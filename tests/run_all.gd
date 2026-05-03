extends SceneTree

## Headless test runner. Discovers `tests/test_*.gd` files, instantiates each
## as a Node, then calls every method whose name starts with `test_`.
##
## Run via:
##   godot --headless --script res://tests/run_all.gd
##
## Exit code 0 = all passed, 1 = at least one failure.

const TEST_ROOT := "res://tests/"

func _initialize() -> void:
	TestAssert.reset()
	var paths := _discover(TEST_ROOT)
	paths.sort()
	var total := 0
	var failed := 0
	print("=== Running %d test file(s) ===" % paths.size())
	for path in paths:
		var script: GDScript = load(path)
		if script == null:
			push_error("Could not load %s" % path)
			failed += 1
			continue
		var instance: Object = script.new()
		var node_name := path.get_file().get_basename()
		if instance is Node:
			(instance as Node).name = node_name
			root.add_child(instance)
		var method_results := _run_methods(instance, node_name)
		total  += method_results[0]
		failed += method_results[1]
		if instance is Node:
			(instance as Node).queue_free()
	print("\n=== %d / %d test(s) passed ===" % [total - failed, total])
	if failed > 0:
		print("\n--- Failures ---")
		for f in TestAssert.failures:
			print("  %s" % f)
		quit(1)
	else:
		quit(0)

func _run_methods(instance: Object, node_name: String) -> Array:
	var ran := 0
	var failed := 0
	for m in instance.get_method_list():
		var name: String = m.name
		if not name.begins_with("test_"):
			continue
		ran += 1
		TestAssert.current_test = "%s::%s" % [node_name, name]
		var fail_count_before := TestAssert.failures.size()
		instance.call(name)
		if TestAssert.failures.size() > fail_count_before:
			failed += 1
			print("  ✗ %s" % TestAssert.current_test)
		else:
			print("  ✓ %s" % TestAssert.current_test)
	return [ran, failed]

func _discover(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full := dir_path + entry
		if dir.current_is_dir():
			out.append_array(_discover(full + "/"))
		elif entry.begins_with("test_") and entry.ends_with(".gd"):
			out.append(full)
		entry = dir.get_next()
	return out
