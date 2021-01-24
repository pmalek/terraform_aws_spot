# terraform_aws_spot

Create AWS spot fleet with a simple terraform command

## How to run

Source AWS credentials and edit `main.tfvars` to suit your needs.

```
key_name="id_rsa"
spot_price=0.02
capacity=1
```

Run `terraform plan` and `terraform apply`:

```
make plan && make apply
```

## How to destroy created resources

```
make destroy
```
