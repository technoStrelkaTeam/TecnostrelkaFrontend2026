import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiClient,
    required this.user,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final UserProfile user;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _loading = false;
  String? _error;
  final List<DemoSubscription> _subscriptions = [];
  final _imapLoginController = TextEditingController();
  final _imapPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seedDemoSubscriptions();
  }

  @override
  void dispose() {
    _imapLoginController.dispose();
    _imapPasswordController.dispose();
    super.dispose();
  }

  void _seedDemoSubscriptions() {
    _subscriptions
      ..clear()
      ..addAll([
        DemoSubscription(
          name: 'Netflix',
          price: 599,
          billingPeriod: 'monthly',
          nextBillingDate: DateTime.now().add(const Duration(days: 7)),
          category: 'Streaming',
          status: 'active',
        ),
        DemoSubscription(
          name: 'Spotify',
          price: 199,
          billingPeriod: 'monthly',
          nextBillingDate: DateTime.now().add(const Duration(days: 15)),
          category: 'Music',
          status: 'active',
        ),
      ]);
  }

  void _removeSubscription(DemoSubscription subscription) {
    setState(() {
      _subscriptions.remove(subscription);
    });
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _addSubscription(DemoSubscriptionDraft draft) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      return;
    }
    setState(() {
      _subscriptions.add(
        DemoSubscription(
          name: draft.name,
          price: draft.price,
          billingPeriod: draft.billingPeriod,
          nextBillingDate: draft.nextBillingDate,
          category: draft.category,
          status: draft.status,
        ),
      );
      _loading = false;
    });
  }

  Future<void> _importFromEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final imapLogin = _imapLoginController.text.trim();
    final imapPassword = _imapPasswordController.text;
    final parsed = <DemoSubscription>[];

    if (imapLogin.isNotEmpty && imapPassword.isNotEmpty) {
      try {
        final response = await widget.apiClient.importFromImap(imapLogin, imapPassword);

        for (final entry in response.entries) {
          final name = entry.key;
          final item = entry.value;
          if (item is Map<String, dynamic>) {
            final cost = item['cost'];
            final nextPay = item['next_pay'];
            final price = cost != null ? double.tryParse(cost.toString()) ?? 0.0 : 0.0;
            final nextDate = _dateFromList(nextPay);
            if (price > 0) {
              parsed.add(DemoSubscription(
                name: name,
                price: price,
                billingPeriod: 'monthly',
                nextBillingDate: nextDate,
                category: 'Imported',
                status: 'active',
              ));
            }
          }
        }
      } catch (e) {
        _error = e.toString();
      }
    } else {
      _error = 'Введите логин и пароль IMAP для импорта.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (parsed.isEmpty) {
        _error ??= 'Не удалось извлечь подписки из письма.';
      } else {
        _subscriptions.addAll(parsed);
        _error = null;
      }
      _loading = false;
    });

    if (parsed.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импорт завершен: добавлено ${parsed.length} подписок')),
      );
    }
  }

  DateTime _dateFromList(dynamic value) {
    if (value is List && value.length >= 3) {
      final year = int.tryParse(value[0]?.toString() ?? '') ?? DateTime.now().year;
      final month = int.tryParse(value[1]?.toString() ?? '') ?? 1;
      final day = int.tryParse(value[2]?.toString() ?? '') ?? 1;
      return DateTime(year, month, day);
    }
    return DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProfileView(apiClient: widget.apiClient, user: widget.user, onLogout: widget.onLogout),
      SubscriptionList(
        subscriptions: _subscriptions,
        loading: _loading,
        error: _error,
        onRefresh: _loadSubscriptions,
        onRemove: _removeSubscription,
      ),
      AddSubscriptionForm(
        onSave: _addSubscription,
        loading: _loading,
      ),
      ImportSubscriptions(
        onImport: _importFromEmail,
        loading: _loading,
        imapLoginController: _imapLoginController,
        imapPasswordController: _imapPasswordController,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Центр подписок'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        onTap: (value) {
          setState(() {
            _index = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Профиль',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Обзор',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Добавить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.email_outlined),
            label: 'Импорт',
          ),
        ],
      ),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.apiClient, required this.user, required this.onLogout});

  final ApiClient apiClient;
  final UserProfile user;
  final VoidCallback onLogout;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? _findByEmailResult;
  bool _loading = false;

  Future<void> _findByEmail() async {
    setState(() {
      _loading = true;
      _findByEmailResult = null;
    });
    try {
      final found = await widget.apiClient.getUserByEmail(widget.user.email);
      setState(() {
        _findByEmailResult = 'Найден пользователь: ${found.name} (${found.email})';
      });
    } catch (e) {
      setState(() {
        _findByEmailResult = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Данные пользователя',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'ID', value: widget.user.id.toString()),
                const SizedBox(height: 8),
                _InfoRow(label: 'Имя', value: widget.user.name),
                const SizedBox(height: 8),
                _InfoRow(label: 'Username', value: widget.user.username ?? '—'),
                const SizedBox(height: 8),
                _InfoRow(label: 'Email', value: widget.user.email),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _findByEmail,
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Проверить по email'),
        ),
        if (_findByEmailResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_findByEmailResult!),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class SubscriptionList extends StatelessWidget {
  const SubscriptionList({
    super.key,
    required this.subscriptions,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.onRemove,
  });

  final List<DemoSubscription> subscriptions;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<DemoSubscription>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (loading && subscriptions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Активные подписки',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (subscriptions.isEmpty && error == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Нет подписок. Добавьте первую подписку на вкладке "Добавить".',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ...subscriptions.map((subscription) => SubscriptionCard(
                subscription,
                onRemove: onRemove,
              )),
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard(
    this.subscription, {
    super.key,
    this.onRemove,
  });

  final DemoSubscription subscription;
  final ValueChanged<DemoSubscription>? onRemove;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd();
    return Card(
      child: ListTile(
        title: Text(subscription.name),
        subtitle: Text(
          '${subscription.category} • ${subscription.billingPeriod}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${subscription.price.toStringAsFixed(2)} RUB'),
                Text(
                  formatter.format(subscription.nextBillingDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
                onPressed: () => onRemove!(subscription),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddSubscriptionForm extends StatefulWidget {
  const AddSubscriptionForm({super.key, required this.onSave, required this.loading});

  final Future<void> Function(DemoSubscriptionDraft draft) onSave;
  final bool loading;

  @override
  State<AddSubscriptionForm> createState() => _AddSubscriptionFormState();
}

class _AddSubscriptionFormState extends State<AddSubscriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Streaming');
  String _billingPeriod = 'monthly';
  String _status = 'active';
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите действительную цену')),
      );
      return;
    }
    final draft = DemoSubscriptionDraft(
      name: _nameController.text.trim(),
      price: price,
      billingPeriod: _billingPeriod,
      nextBillingDate: _nextBillingDate,
      category: _categoryController.text.trim().isEmpty
          ? 'Other'
          : _categoryController.text.trim(),
      status: _status,
    );
    await widget.onSave(draft);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Подписка добавлена')),
    );
    _formKey.currentState!.reset();
    _nameController.clear();
    _priceController.clear();
    _categoryController.text = 'Streaming';
    setState(() {
      _billingPeriod = 'monthly';
      _status = 'active';
      _nextBillingDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date != null) {
      setState(() {
        _nextBillingDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.yMMMd();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Добавить подписку',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название сервиса',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цена (RUB)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите цену';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _billingPeriod,
                decoration: const InputDecoration(
                  labelText: 'Период выставления счета',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Ежемесячно')),
                  DropdownMenuItem(value: 'yearly', child: Text('Ежегодно')),
                  DropdownMenuItem(value: 'weekly', child: Text('Еженедельно')),
                ],
                onChanged: widget.loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _billingPeriod = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Статус подписки',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Активная')),
                  DropdownMenuItem(value: 'paused', child: Text('Пауза')),
                  DropdownMenuItem(value: 'canceled', child: Text('Отменена')),
                ],
                onChanged: widget.loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Следующий платеж: ${formatter.format(_nextBillingDate)}'),
                  ),
                  TextButton(
                    onPressed: widget.loading ? null : _pickDate,
                    child: const Text('Выберете дату'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(widget.loading ? 'Сохранение...' : 'Сохранить подписку'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ImportSubscriptions extends StatelessWidget {
  const ImportSubscriptions({
    super.key,
    required this.onImport,
    required this.loading,
    required this.imapLoginController,
    required this.imapPasswordController,
  });

  final Future<void> Function() onImport;
  final bool loading;
  final TextEditingController imapLoginController;
  final TextEditingController imapPasswordController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Импорт из электронной почты',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Импортировать подписки по IMAP (логин/пароль).',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: imapLoginController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'IMAP login (email)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: imapPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'IMAP password',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loading ? null : onImport,
            icon: const Icon(Icons.play_arrow),
            label: Text(loading ? 'Импорт...' : 'Запустить импорт'),
          ),
        ],
      ),
    );
  }
}

class DemoSubscription {
  DemoSubscription({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.nextBillingDate,
    required this.category,
    required this.status,
  });

  final String name;
  final double price;
  final String billingPeriod;
  final DateTime nextBillingDate;
  final String category;
  final String status;
}

class DemoSubscriptionDraft {
  DemoSubscriptionDraft({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.nextBillingDate,
    required this.category,
    required this.status,
  });

  final String name;
  final double price;
  final String billingPeriod;
  final DateTime nextBillingDate;
  final String category;
  final String status;
}
