# 1. Purani (Existing) Organization ka data lena
data "aws_organizations_organization" "org" {}

# 2. SCP: Prevent CloudTrail Deletion
resource "aws_organizations_policy" "deny_stop_logging" {
  name        = "deny-stop-logging"
  description = "Prevents anyone from stopping or deleting CloudTrail"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail"]
        Resource = "*"
      }
    ]
  })
}

# 3. SCP ko Root level par attach karna
resource "aws_organizations_policy_attachment" "root_attach" {
  policy_id = aws_organizations_policy.deny_stop_logging.id
  target_id = data.aws_organizations_organization.org.roots[0].id
}

# 4. Secure VPC (VPC Segmentation)
resource "aws_vpc" "landing_zone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = { Name = "Secure-Landing-Zone-VPC" }
}

# Private Subnet (No Direct Internet Access)
resource "aws_subnet" "private_zone" {
  vpc_id     = aws_vpc.landing_zone_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = { Name = "Private-Subnet" }
}

# 5. GuardDuty (Org-wide Threat Detection)
resource "aws_guardduty_detector" "main" {
  enable = true
}