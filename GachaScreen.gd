# GachaScreen.gd
extends Control

# == ตัวแปรสำหรับตั้งค่าใน Inspector (Godot 3) ==
export var single_pull_cost: int = 10
export var multi_pull_cost: int = 100

# cú pháp สำหรับ Godot 3 เพื่อให้ลาก Resource ใส่ Array ได้
export (Array, Resource) var pool_3_star
export (Array, Resource) var pool_2_star
export (Array, Resource) var pool_1_star


# == ตัวแปรภายใน (จำลองว่ามีเงิน) ==
var current_shards: int = 500

# == ลิงก์ไปยัง Nodes (Godot 3 ใช้ onready ไม่มี @) ==
onready var result_name_label: Label = $ResultName
onready var result_image_rect: TextureRect = $ResultImage


func _ready():
	randomize()
	print("ระบบกาฉาพร้อม! มี %d Shards" % current_shards)


# == ฟังก์ชันที่เชื่อมต่อกับปุ่ม (จะทำในขั้นตอนที่ 5) ==

func _on_SinglePullButton_pressed(): # ชื่อฟังก์ชันต้องตรงกับตอนที่เชื่อม Signal
	if current_shards >= single_pull_cost:
		current_shards -= single_pull_cost
		print("ใช้ %d Shards, เหลือ %d" % [single_pull_cost, current_shards])

		var result: CompanionData = _perform_pull()

		# Output: แสดงผลลัพธ์บน UI
		if result:
			result_name_label.text = "ยินดีด้วย! คุณได้: %s (%d ดาว)" % [result.character_name, result.rarity]
			result_image_rect.texture = result.texture
			print("สุ่มได้: %s" % result.character_name)

	else:
		result_name_label.text = "Shard of Life ไม่เพียงพอ!"
		print("Shard of Life ไม่เพียงพอ!")

func _on_MultiPullButton_pressed(): # ชื่อฟังก์ชันต้องตรง
	if current_shards >= multi_pull_cost:
		current_shards -= multi_pull_cost
		print("ใช้ %d Shards, เหลือ %d" % [multi_pull_cost, current_shards])

		var results_list: Array = []
		for i in 10:
			results_list.append(_perform_pull())

		# Output: แสดงผลลัพธ์ (แสดงแค่ตัวสุดท้ายเป็นตัวอย่าง)
		if not results_list.empty():
			var last_result = results_list.back()
			result_name_label.text = "สุ่มได้ 10 ตัว (แสดงตัวสุดท้าย): %s" % last_result.character_name
			result_image_rect.texture = last_result.texture

			print("สุ่มได้ 10 ครั้ง:")
			for companion in results_list:
				print("- %s (%d ดาว)" % [companion.character_name, companion.rarity])
	else:
		result_name_label.text = "Shard of Life ไม่เพียงพอ!"
		print("Shard of Life ไม่เพียงพอ!")


# == ตรรกะการสุ่มหลัก ==

func _perform_pull() -> CompanionData:
	# ตรวจสอบก่อนว่า Pool ว่างหรือไม่
	if pool_1_star.empty() or pool_2_star.empty() or pool_3_star.empty():
		printerr("Gacha Error: Pool ว่างเปล่า! กรุณาใส่ตัวละครใน Inspector")
		return null

	var roll = randi() % 100 + 1

	var selected_pool: Array

	if roll <= 10: # 10%
		selected_pool = pool_3_star
	elif roll <= 50: # 40% (11-50)
		selected_pool = pool_2_star
	else: # 50% (51-100)
		selected_pool = pool_1_star

	var random_index = randi() % selected_pool.size()
	return selected_pool[random_index]
