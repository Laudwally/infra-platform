variable "name" {
  type = string
}

variable "monthly_budget_limit_usd" {
  type    = number
  default = 500
}

variable "alert_emails" {
  description = "Emails notified at 80% and 100% of the monthly budget."
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
