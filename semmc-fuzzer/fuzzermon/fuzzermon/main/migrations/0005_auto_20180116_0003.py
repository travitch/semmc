# Generated by Django 2.0.1 on 2018-01-16 00:03

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('main', '0004_auto_20180116_0000'),
    ]

    operations = [
        migrations.RenameField(
            model_name='batch',
            old_name='host',
            new_name='testing_host',
        ),
        migrations.AddField(
            model_name='batch',
            name='fuzzer_host',
            field=models.CharField(default='', max_length=128),
            preserve_default=False,
        ),
    ]
