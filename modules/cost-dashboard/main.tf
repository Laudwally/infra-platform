resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }
}

# Billing metrics only publish to CloudWatch in us-east-1, regardless of
# which region this dashboard resource itself is created in.
resource "aws_cloudwatch_dashboard" "cost" {
  dashboard_name = "${var.name}-cost"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Estimated monthly charges (USD)"
          region  = "us-east-1"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 21600
          stat   = "Maximum"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 6
        width  = 12
        height = 2
        properties = {
          markdown = format(
            "Budget alerts fire at 80%% (forecasted) and 100%% (actual) of the $%s/month budget, emailed to: %s",
            var.monthly_budget_limit_usd,
            join(", ", var.alert_emails),
          )
        }
      }
    ]
  })
}
