class_name LootTable
extends Resource

@export var entries:        Array[LootEntry] = []
@export var drop_count_min: int = 1
@export var drop_count_max: int = 1

func roll(rng: RandomNumberGenerator) -> Array[ItemData]:
	var results: Array[ItemData] = []
	if entries.is_empty():
		return results
	var total := 0.0
	for e in entries:
		total += e.weight
	var count := rng.randi_range(drop_count_min, drop_count_max)
	for _i in count:
		var r   := rng.randf() * total
		var cum := 0.0
		for e in entries:
			cum += e.weight
			if r <= cum:
				results.append(e.item)
				break
	return results
