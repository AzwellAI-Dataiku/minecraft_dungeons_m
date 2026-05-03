class_name ObjectPool
extends Node

@export var scene: PackedScene
@export var initial_size: int = 8
@export var max_size: int = 32

var _pool: Array[Node] = []

func _ready() -> void:
	if scene == null:
		return
	for i in initial_size:
		_pool.append(_make())

func acquire() -> Node:
	for n in _pool:
		if not n.visible:
			n.visible = true
			return n
	if _pool.size() < max_size:
		var n := _make()
		n.visible = true
		return n
	# Recycle oldest entry
	var n := _pool[0]
	_pool.append(_pool.pop_front())
	n.visible = true
	return n

func release(node: Node) -> void:
	node.visible = false

func _make() -> Node:
	var n := scene.instantiate()
	n.visible = false
	add_child(n)
	return n
