import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'Dashboard',
    'Contacts',
    'Meetings',
    'Tasks',
    'Communication',
    'Calendar',
    'Global Search',
    'Profile',
  ];

  final List<IconData> icons = [
    Icons.dashboard_outlined,
    Icons.contacts_outlined,
    Icons.groups_outlined,
    Icons.task_alt_outlined,
    Icons.chat_outlined,
    Icons.calendar_month_outlined,
    Icons.search,
    Icons.person_outline,
  ];

  final List<String> routes = [
    '/dashboard',
    '/contacts',
    '/meetings',
    '/tasks',
    '/communication',
    '/calendar',
    '/search',
    '/profile',
  ];

  void openScreen(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index != 0) {
      Navigator.pushNamed(context, routes[index]).then((_) {
        setState(() {
          selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: openScreen,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.hub,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SmartMeet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            destinations: List.generate(
              titles.length,
              (index) => NavigationRailDestination(
                icon: Icon(icons[index]),
                label: Text(titles[index]),
              ),
            ),
          ),

          const VerticalDivider(
            width: 1,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning 👋',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Welcome to DS1CPSmartMeet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 32),

                  GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _dashboardCard(
                        'Contacts',
                        'Manage your contacts',
                        Icons.contacts_outlined,
                        '/contacts',
                      ),
                      _dashboardCard(
                        'Meetings',
                        'Manage meetings',
                        Icons.groups_outlined,
                        '/meetings',
                      ),
                      _dashboardCard(
                        'Tasks',
                        'Track your tasks',
                        Icons.task_alt_outlined,
                        '/tasks',
                      ),
                      _dashboardCard(
                        'Communication',
                        'View communication',
                        Icons.chat_outlined,
                        '/communication',
                      ),
                      _dashboardCard(
                        'Calendar',
                        'View your schedule',
                        Icons.calendar_month_outlined,
                        '/calendar',
                      ),
                      _dashboardCard(
                        'Global Search',
                        'Search across the system',
                        Icons.search,
                        '/search',
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    'System Architecture',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          _architectureItem(
                            Icons.phone_android,
                            'Flutter',
                            'User Interface',
                          ),
                          _arrow(),
                          _architectureItem(
                            Icons.api,
                            'API',
                            'Backend',
                          ),
                          _arrow(),
                          _architectureItem(
                            Icons.storage,
                            'Database',
                            'Persistent Data',
                          ),
                          _arrow(),
                          _architectureItem(
                            Icons.account_tree,
                            'C++17',
                            'DSA Engine',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(
    String title,
    String description,
    IconData icon,
    String route,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _architectureItem(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _arrow() {
    return const Icon(
      Icons.arrow_forward,
      size: 22,
    );
  }
}