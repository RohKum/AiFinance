#!/bin/bash

# Navigate to the lib folder
cd lib || exit

# Create core structure
mkdir -p core/constants core/utils core/services core/theme
touch app.dart
touch core/constants/app_constants.dart core/constants/api_constants.dart
touch core/utils/date_utils.dart core/utils/currency_utils.dart
touch core/services/firebase_service.dart core/services/ai_service.dart core/services/sms_service.dart core/services/speech_service.dart
touch core/theme/app_theme.dart

# Create data structure
mkdir -p data/models data/repositories
touch data/models/user_model.dart data/models/expense_model.dart data/models/category_model.dart data/models/budget_model.dart
touch data/repositories/auth_repository.dart data/repositories/expense_repository.dart data/repositories/ai_repository.dart

# Create feature structure
mkdir -p features/auth/screens features/auth/providers
touch features/auth/screens/login_screen.dart features/auth/screens/signup_screen.dart
touch features/auth/providers/auth_provider.dart

mkdir -p features/dashboard/screens features/dashboard/widgets
touch features/dashboard/screens/dashboard_screen.dart
touch features/dashboard/widgets/balance_card.dart features/dashboard/widgets/expense_chart.dart features/dashboard/widgets/recent_transactions.dart

mkdir -p features/expense/screens features/expense/widgets features/expense/providers
touch features/expense/screens/add_expense_screen.dart features/expense/screens/expense_list_screen.dart
touch features/expense/widgets/expense_tile.dart features/expense/widgets/category_selector.dart
touch features/expense/providers/expense_provider.dart

mkdir -p features/ai_insights/screens features/ai_insights/widgets features/ai_insights/providers
touch features/ai_insights/screens/ai_insights_screen.dart
touch features/ai_insights/widgets/insight_card.dart features/ai_insights/widgets/chat_bubble.dart
touch features/ai_insights/providers/ai_provider.dart

mkdir -p features/voice/services
touch features/voice/services/voice_command_handler.dart

mkdir -p features/budget/screens features/budget/providers
touch features/budget/screens/budget_screen.dart
touch features/budget/providers/budget_provider.dart

# Create routes structure
mkdir -p routes
touch routes/app_routes.dart routes/route_names.dart

# Create shared widgets structure
mkdir -p shared/widgets
touch shared/widgets/custom_button.dart shared/widgets/custom_textfield.dart shared/widgets/loading_indicator.dart

echo "Successfully created the feature-based folder structure!"
