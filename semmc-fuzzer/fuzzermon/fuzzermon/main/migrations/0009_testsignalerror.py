# Generated by Django 2.0.1 on 2018-01-18 21:16

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('main', '0008_auto_20180117_0003'),
    ]

    operations = [
        migrations.CreateModel(
            name='TestSignalError',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('pretty', models.CharField(max_length=256)),
                ('signal', models.IntegerField()),
                ('batch', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='main.Batch')),
                ('opcode', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='main.Opcode')),
            ],
        ),
    ]