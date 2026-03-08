class_name DamageReceiver
extends Area2D

enum HITtype {NORMAL, KNOCKBACK, POWER}

signal damage_received(damage : int, direction : Vector2, hit_type : HITtype)
