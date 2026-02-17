---
tags:
  - aws
  - audit-manager
  - compliance
  - security
  - governance
  - organizations
  - risk-management
---

# Component: `audit-manager`

This component is responsible for configuring AWS Audit Manager within an AWS Organization.

AWS Audit Manager helps you continuously audit your AWS usage to simplify how you assess risk and compliance with
regulations and industry standards. It automates evidence collection, organizes compliance data, and generates
audit-ready reports.

## Key Features

- **Prebuilt Frameworks**: AWS Control Tower, CIS, FedRAMP, GDPR, HIPAA, PCI DSS, SOC 2, NIST 800-53
- **Custom Controls**: Build custom frameworks and controls for specific business requirements
- **Automated Evidence**: Collects evidence from CloudTrail, Config, Security Hub, License Manager
- **Multi-account**: Supports assessments across multiple AWS accounts via AWS Organizations
- **Delegation Workflow**: Delegate control sets to specialized team members
- **Evidence Search**: Search through thousands of pieces of collected evidence with filters and groupings
- **Assessment Reports**: Cryptographically verified reports with organized evidence
- **Manual Evidence**: Upload policy documents, training transcripts, architecture diagrams

## Component Features

- **Single-Step Deployment**: Unique deployment model - enables and delegates in a single step from the root account
- **Prebuilt Frameworks**: Supports PCI DSS, HIPAA, SOC 2, NIST 800-53, FedRAMP, GDPR, CIS, and more
- **Automated Evidence Collection**: Collects evidence from CloudTrail, Config, Security Hub, License Manager
- **Account Verification**: Optional safety check that validates Terraform is running in the correct AWS account
- **Flexible Account Map**: Supports both remote-state account-map lookups and static account map variables (default)

## Architecture

Audit Manager uses a **unique single-step deployment model** different from other AWS security services:

| Component | Description |
|-----------|-------------|
| **Organization Management Account** | Enables Audit Manager AND delegates administration in a single deployment |
| **Delegated Administrator Account** | Receives delegated administration automatically, creates/manages assessments |
| **Member Accounts** | Evidence automatically collected, no additional configuration required |

## Deployment Model Comparison

| Aspect | AWS Audit Manager | AWS Inspector2 | AWS Access Analyzer |
|--------|-------------------|----------------|---------------------|
| **Deployment Approach** | Single-step in root account only | Delegated administrator (2 steps) | Delegated administrator (2 steps) |
| **Member Account Setup** | No setup (evidence auto-collected) | Auto-enabled by delegated admin | No setup (auto-analyzed) |
| **Provisioning Steps** | 1 step (root only) | 2 steps (root → security) | 2 steps (root → security) |

## Regional Deployment

Audit Manager is a regional service. You must deploy it to each region where you want to run compliance assessments.
Assessment reports are stored in region-specific S3 buckets.

## Service-Linked Role

AWS Audit Manager automatically creates a service-linked role when you enable the service. No manual role creation is
required.

## Assessment Report S3 Buckets

When generating assessment reports, Audit Manager publishes reports to an S3 bucket of your choice:

- **Same-Region Buckets**: Recommended. Supports up to 22,000 evidence items (vs. 3,500 for cross-region)
- **Encryption**: If using SSE-KMS, the KMS key must match your Audit Manager data encryption settings
- **Account**: Use buckets in the delegated administrator account (cross-account not recommended)
- **Per-Region**: Create a bucket in each region where you'll run assessments

## Configuration

### Defaults (Abstract Component)

```yaml
components:
  terraform:
    aws-audit-manager/defaults:
      metadata:
        component: aws-audit-manager
        type: abstract
      vars:
        enabled: true
        global_environment: gbl
        account_map_tenant: core
        root_account_stage: root
        delegated_administrator_account_name: core-security
        deregister_on_destroy: true
```

### Root Account Configuration (Single-Step Deployment)

```yaml
import:
  - catalog/aws-audit-manager/defaults

components:
  terraform:
    # Single-step: Enable Audit Manager and delegate administration
    aws-audit-manager/root:
      metadata:
        component: aws-audit-manager
        inherits:
          - aws-audit-manager/defaults
      vars:
        # Requires SuperAdmin permissions
        privileged: true
```

## Provisioning

Deploy to the organization management (root) account for each region where you want assessments:

```bash
# Deploy to us-east-1
atmos terraform apply aws-audit-manager/root -s core-use1-root

# Deploy to us-west-2
atmos terraform apply aws-audit-manager/root -s core-usw2-root
```

This single deployment:
- Enables Audit Manager in the organization
- Delegates administration to the security account
- Begins automatic evidence collection from member accounts

## Assessment Report S3 Bucket Setup

Create S3 buckets in the delegated administrator (security) account for each region:

```yaml
# stacks/catalog/s3-bucket/audit-manager-reports.yaml
import:
  - catalog/s3-bucket/defaults

components:
  terraform:
    audit-manager-reports-bucket:
      metadata:
        component: s3-bucket
        inherits:
          - s3-bucket/defaults
      vars:
        enabled: true
        name: audit-manager-reports
        s3_object_ownership: "BucketOwnerEnforced"
        versioning_enabled: false
```

Deploy to each region in the security account:

```bash
atmos terraform apply audit-manager-reports-bucket -s core-use1-security
atmos terraform apply audit-manager-reports-bucket -s core-usw2-security
```

## Creating Assessments

After deploying Audit Manager, create assessments in the delegated administrator account:

1. **Via Console**: AWS Audit Manager console → Assessments → Create assessment
2. **Via CLI**: Use `aws auditmanager` CLI commands
3. **Via Terraform**: Use `aws_auditmanager_assessment` resource

**Assessment Components:**
- **Framework**: Choose prebuilt or custom framework
- **Scope**: Select AWS accounts and services to assess
- **Roles**: Define who can access the assessment
- **Report Destination**: Specify S3 bucket for reports

## Cost Considerations

- **Assessment Price**: Based on number of evidence items collected per month
- **Evidence Storage**: S3 storage costs for assessment reports
- **Evidence Finder**: Additional cost if enabling CloudTrail Lake integration
- **Free Tier**: Limited free usage during first 13 months
- **Regional**: Costs are per region

See [AWS Audit Manager Pricing](https://aws.amazon.com/audit-manager/pricing/) for current rates.

## Compliance Frameworks Supported

Audit Manager provides prebuilt frameworks for common compliance standards:

- **PCI DSS**: Payment Card Industry Data Security Standard
- **HIPAA**: Health Insurance Portability and Accountability Act
- **SOC 2**: Service Organization Control 2
- **NIST 800-53**: National Institute of Standards and Technology (Rev 4 and Rev 5)
- **FedRAMP**: Federal Risk and Authorization Management Program
- **GDPR**: General Data Protection Regulation
- **ISO 27001**: Information Security Management
- **CIS**: Center for Internet Security benchmarks (v1.2.0, v1.3.0, v1.4.0, v7.1, v8)
- **GxP**: Good Practice quality guidelines (21 CFR Part 11)
- **AWS Control Tower**: AWS Control Tower guardrails

## References

### AWS Documentation
- [What is AWS Audit Manager?](https://docs.aws.amazon.com/audit-manager/latest/userguide/what-is.html)
- [Setting Up AWS Audit Manager](https://docs.aws.amazon.com/audit-manager/latest/userguide/setting-up.html)
- [Assessment Settings](https://docs.aws.amazon.com/audit-manager/latest/userguide/assessment-settings.html)
- [Audit Manager Frameworks](https://docs.aws.amazon.com/audit-manager/latest/userguide/frameworks.html)
- [Evidence Collection](https://docs.aws.amazon.com/audit-manager/latest/userguide/evidence.html)
- [Delegated Administrator](https://docs.aws.amazon.com/audit-manager/latest/userguide/delegated-admin.html)

### Terraform Resources
- [aws_auditmanager_account_registration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_account_registration)
- [aws_auditmanager_organization_admin_account_registration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_organization_admin_account_registration)
- [aws_auditmanager_assessment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_assessment)
- [aws_auditmanager_control](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_control)
- [aws_auditmanager_framework](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_framework)

### Additional Resources
- [AWS Audit Manager Product Page](https://aws.amazon.com/audit-manager/)
- [AWS Audit Manager Pricing](https://aws.amazon.com/audit-manager/pricing/)
- [AWS Audit Manager Features](https://aws.amazon.com/audit-manager/features/)


<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.66.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.66.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_account_map"></a> [account\_map](#module\_account\_map) | cloudposse/stack-config/yaml//modules/remote-state | 1.8.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_auditmanager_account_registration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_account_registration) | resource |
| [aws_auditmanager_organization_admin_account_registration.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_organization_admin_account_registration) | resource |
| [terraform_data.account_verification](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_map"></a> [account\_map](#input\_account\_map) | Static account map configuration. Only used when `account_map_enabled` is `false`.<br/>Map keys use `tenant-stage` format (e.g., `core-security`, `core-audit`, `plat-prod`). | <pre>object({<br/>    full_account_map              = map(string)<br/>    audit_account_account_name    = optional(string, "")<br/>    root_account_account_name     = optional(string, "")<br/>    identity_account_account_name = optional(string, "")<br/>    aws_partition                 = optional(string, "aws")<br/>    iam_role_arn_templates        = optional(map(string), {})<br/>  })</pre> | <pre>{<br/>  "audit_account_account_name": "",<br/>  "aws_partition": "aws",<br/>  "full_account_map": {},<br/>  "iam_role_arn_templates": {},<br/>  "identity_account_account_name": "",<br/>  "root_account_account_name": ""<br/>}</pre> | no |
| <a name="input_account_map_component_name"></a> [account\_map\_component\_name](#input\_account\_map\_component\_name) | The name of the account-map component | `string` | `"account-map"` | no |
| <a name="input_account_map_enabled"></a> [account\_map\_enabled](#input\_account\_map\_enabled) | Enable the account map component. When true, the component fetches account mappings from the<br/>`account-map` component via remote state. When false (default), the component uses the static `account_map` variable instead. | `bool` | `false` | no |
| <a name="input_account_map_tenant"></a> [account\_map\_tenant](#input\_account\_map\_tenant) | The tenant where the `account_map` component required by remote-state is deployed | `string` | `"core"` | no |
| <a name="input_account_verification_enabled"></a> [account\_verification\_enabled](#input\_account\_verification\_enabled) | Enable account verification. When true (default), the component verifies that Terraform is executing<br/>in the correct AWS account by comparing the current account ID against the expected account from the<br/>account\_map based on the component's tenant-stage context. | `bool` | `true` | no |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_delegated_administrator_account_name"></a> [delegated\_administrator\_account\_name](#input\_delegated\_administrator\_account\_name) | The name of the account that is the AWS Organization Delegated Administrator account | `string` | `"core-security"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_deregister_on_destroy"></a> [deregister\_on\_destroy](#input\_deregister\_on\_destroy) | Flag to deregister AuditManager in the account upon destruction. If set to `false`, AuditManager will remain active in the account, even if this resource is removed | `bool` | `true` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_global_environment"></a> [global\_environment](#input\_global\_environment) | Global environment name | `string` | `"gbl"` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_organization_management_account_name"></a> [organization\_management\_account\_name](#input\_organization\_management\_account\_name) | The name of the AWS Organization management account | `string` | `null` | no |
| <a name="input_privileged"></a> [privileged](#input\_privileged) | true if the default provider already has access to the backend | `bool` | `false` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_root_account_stage"></a> [root\_account\_stage](#input\_root\_account\_stage) | The stage name for the Organization root (management) account. This is used to lookup account IDs from account names<br/>using the `account-map` component. | `string` | `"root"` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_registration_id"></a> [account\_registration\_id](#output\_account\_registration\_id) | Unique identifier for the account registration |
| <a name="output_account_registration_status"></a> [account\_registration\_status](#output\_account\_registration\_status) | Status of the account registration request |
| <a name="output_organization_administrator_account_id"></a> [organization\_administrator\_account\_id](#output\_organization\_administrator\_account\_id) | Organization administrator account ID |
<!-- markdownlint-restore -->




[<img src="https://cloudposse.com/logo-300x69.svg" height="32" align="right"/>](https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-audit-manager&utm_content=)

