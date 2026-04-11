import 'package:aifin/features/auth/screens/login_screen.dart';
import 'package:aifin/features/auth/screens/signup_screen.dart';
import 'package:aifin/features/dashboard/screens/dashboard_screen.dart';
import 'package:aifin/features/expense/screens/add_expense_screen.dart';
import 'package:aifin/features/expense/screens/expense_list_screen.dart';
import 'package:aifin/features/ai_insights/screens/ai_insights_screen.dart';
import 'package:aifin/features/budget/screens/budget_screen.dart';
import 'package:flutter/material.dart';
import 'package:aifin/routes/route_names.dart';

import 'package:aifin/features/profile/screens/profile_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case RouteNames.addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      case RouteNames.expenseList:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
      case RouteNames.aiInsights:
        return MaterialPageRoute(builder: (_) => const AiInsightsScreen());
      case RouteNames.budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
