terraform {
  required_version = ">=0.11.0"
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.name}Profile"
  path = "${var.path}"
  role = "${aws_iam_role.main.name}"
}

resource "aws_iam_role" "main" {
  name               = "${var.name}Role"
  path               = "${var.path}"
  description        = "Role assigned to the ${var.name}Profile instance profile (generated by Terraform)"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
  tags               = "${var.tags}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "user_policies" {
  name        = "${var.name}Policy-${count.index}"
  path        = "${var.path}"
  description = "User-managed policy assigned to the ${var.name}Role role (generated by Terraform)"
  policy      = "${var.policy_jsons[count.index]}"
  count       = "${length(var.policy_jsons)}"
}

resource "aws_iam_role_policy_attachment" "user_policies" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "${element(aws_iam_policy.user_policies.*.arn, count.index)}"
  count      = "${length(var.policy_jsons)}"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  count      = "${var.attach_ssm_policy ? 1 : 0}"
}

resource "aws_iam_role_policy_attachment" "cwagent_policy" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  count      = "${var.attach_cwagent_policy ? 1 : 0}"
}

resource "aws_iam_role_policy_attachment" "attached_policies" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "${var.policy_arns[count.index]}"
  count      = "${length(var.policy_arns)}"
}
