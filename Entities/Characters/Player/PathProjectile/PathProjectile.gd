extends RigidBody2D

#variables
var initial_impulse = Vector2.ZERO
var init_flag = true #ensures pulse is applied only once
var path_projectile_mult = 0


func _ready():
	gravity_scale *= path_projectile_mult
	initial_impulse *= path_projectile_mult


func _integrate_forces(state):
	if init_flag:
		init_flag = false
		apply_central_impulse(initial_impulse)


func _on_LifeTimer_timeout():
	queue_free()


func _on_PathProjectile_body_entered(body):
	queue_free()
