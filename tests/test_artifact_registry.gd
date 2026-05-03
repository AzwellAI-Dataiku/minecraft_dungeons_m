extends Node

func test_known_ids_present() -> void:
	for id in [&"tnt_charge", &"harvester_pulse", &"shockwave"]:
		TestAssert.ok(ArtifactEffects.has(id), "registry should know %s" % id)

func test_unknown_id_rejected() -> void:
	TestAssert.ok(not ArtifactEffects.has(&"made_up_artifact"), "unknown id rejected")

func test_ids_list_matches_count() -> void:
	TestAssert.equal(ArtifactEffects.ids().size(), 3, "exactly 3 effects registered")

func test_data_files_resolve_to_known_ids() -> void:
	for tres in [
		"res://data/items/artifact_tnt.tres",
		"res://data/items/artifact_harvester.tres",
		"res://data/items/artifact_shockwave.tres",
	]:
		var item: ItemData = load(tres) as ItemData
		TestAssert.ok(item != null, "loads: %s" % tres)
		if item == null: continue
		TestAssert.equal(item.type, ItemData.Type.ARTIFACT, "%s is ARTIFACT type" % tres)
		TestAssert.ok(ArtifactEffects.has(item.artifact_id), "%s.artifact_id = %s known" % [tres, item.artifact_id])

func test_unknown_activation_returns_zero() -> void:
	# activate() pushes warning + returns 0.0 for unknown ids; we don't actually
	# call _process logic (would need a scene), so we just exercise the dispatch.
	var cd := ArtifactEffects.activate(&"definitely_not_real", null, null)
	TestAssert.near(cd, 0.0, 0.001, "unknown id → 0 cooldown")
