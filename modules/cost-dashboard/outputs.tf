output "budget_name" {
  value = aws_budgets_budget.monthly.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.cost.dashboard_name
}
