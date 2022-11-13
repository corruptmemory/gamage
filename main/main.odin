package main

import "core:log"
import "vendor:raylib"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:math/rand"
import "core:math/linalg"
import "core:mem"


total_rocks :: 1000
screen_width :: 1920
screen_height :: 1080
target_fps :: 60
default: raylib.Shader
rock: raylib.Model
camera: raylib.Camera
rock_color := raylib.Color{80, 80, 80, 255}
rock_position := raylib.Vector3{0.0, 0.0, 0.0}
center := raylib.Vector3{0.0, 0.0, 0.0}
rock_texture: raylib.Texture2D
rock_normal: raylib.Texture2D
fixed_target : raylib.Vector3
fixed_up :: raylib.Vector3{0, 0, 1}
target: raylib.Vector3
up := fixed_up
position: raylib.Vector3
acceleration: f32 : 0.01
turn_acceleration: f32 : 0.0001
speed: f32 = 0
up_down: f32 = 0
up_down_speed: f32 = 0
left_right: f32 = 0
left_right_speed: f32 = 0
max_speed :: 2.0
max_turn_speed :: 0.1

Rock_State :: struct {
	id:             int,
	scale:          f32,
	position:       raylib.Vector3,
	rotation_axis:  raylib.Vector3,
	rotation:       f32,
	rotation_delta: f32,
}

rocks := [total_rocks]Rock_State{}

random_vec :: proc(rng: ^rand.Rand, lo, hi: f32) -> raylib.Vector3 {
	return(
		raylib.Vector3{
			rand.float32_range(lo, hi, rng),
			rand.float32_range(lo, hi, rng),
			rand.float32_range(lo, hi, rng),
		})
}

build_rocks :: proc(rng: ^rand.Rand, blo, bhi: f32) {
	for i := 0; i < total_rocks; i += 1 {
		r := &rocks[i]
		r.id = i
		r.scale = rand.float32_range(0.1, 0.8, rng)
		r.position = random_vec(rng, blo, bhi)
		r.rotation_axis = random_vec(rng, 0, 1.0)
		r.rotation = rand.float32_range(0, 360, rng)
		r.rotation_delta = rand.float32_range(-0.4, 0.4, rng)
	}
}

draw_rock :: proc(idx: int) {
	r := &rocks[idx]
	raylib.rlPushMatrix()
	raylib.rlTranslatef(r.position.x, r.position.y, r.position.z)
	raylib.rlPushMatrix()
	raylib.rlRotatef(r.rotation, r.rotation_axis.x, r.rotation_axis.y, r.rotation_axis.z)
	raylib.DrawModel(rock, raylib.Vector3{0, 0, 0}, r.scale, raylib.WHITE)
	raylib.rlPopMatrix()
	raylib.rlPopMatrix()
}

update_rock :: proc(idx: int) {
	r := &rocks[idx]
	r.rotation += r.rotation_delta
	if r.rotation >= 360 {
		r.rotation -= 360
	}
}

update_camera :: proc() {
	if raylib.IsKeyDown(raylib.KeyboardKey.SPACE) {
		speed += acceleration
		if speed > max_speed {
			speed = max_speed
		}
	} else {
		speed -= acceleration
		if speed < 0 {
			speed = 0
		}
	}

	w := raylib.IsKeyDown(raylib.KeyboardKey.W)
	s := raylib.IsKeyDown(raylib.KeyboardKey.S)
	a := raylib.IsKeyDown(raylib.KeyboardKey.A)
	d := raylib.IsKeyDown(raylib.KeyboardKey.D)

	switch {
	case w && s:
		up_down_speed = 0
	case w:
		up_down_speed += turn_acceleration
		if up_down_speed > max_turn_speed {
			up_down_speed = max_turn_speed
		}
	case s:
		up_down_speed -= turn_acceleration
		if up_down_speed < -max_turn_speed {
			up_down_speed = -max_turn_speed
		}
	case:
		if up_down_speed > 0 {
			up_down_speed -= turn_acceleration
			if up_down_speed < 0 {
				up_down_speed = 0
			}
		} else if up_down_speed < 0 {
			up_down_speed += turn_acceleration
			if up_down_speed > 0 {
				up_down_speed = 0
			}
		}
	}
	up_down += up_down_speed

	switch {
	case a && d:
		left_right_speed = 0
	case a:
		left_right_speed += turn_acceleration
		if left_right_speed > max_turn_speed {
			left_right_speed = max_turn_speed
		}
	case d:
		left_right_speed -= turn_acceleration
		if left_right_speed < -max_turn_speed {
			left_right_speed = -max_turn_speed
		}
	case:
		if left_right_speed > 0 {
			left_right_speed -= turn_acceleration
			if left_right_speed < 0 {
				left_right_speed = 0
			}
		} else if left_right_speed < 0 {
			left_right_speed += turn_acceleration
			if left_right_speed > 0 {
				left_right_speed = 0
			}
		}
	}
	left_right += left_right_speed

	right := linalg.cross(target, up)
	qud := linalg.quaternion_angle_axis(up_down_speed, right)
	qlr := linalg.quaternion_angle_axis(left_right_speed, up)
	q := qud*qlr
	up = linalg.quaternion_mul_vector3(q, up)
	target = linalg.quaternion_mul_vector3(q, target)
	position += target * speed
}

main :: proc() {
	context.logger = log.create_console_logger()
	rng: rand.Rand
	rand.init(&rng, auto_cast time.time_to_unix(time.now()))
	raylib.InitWindow(screen_width, screen_height, "-- Game: The Game --")
	raylib.SetTargetFPS(target_fps)
	rock = raylib.LoadModel("resources/models/source/rock.obj")
	rock_texture = raylib.LoadTexture("resources/models/textures/rock-tex.png")
	rock_normal = raylib.LoadTexture("resources/models/textures/rock-nor.png")
	position = raylib.Vector3{target.x, -600.0, target.z}
	fixed_target = linalg.normalize(center - position)
	target = fixed_target

	log.infof("target: %v", target)

	default = raylib.LoadShader("resources/shaders/default.vs", "resources/shaders/default.fs")
	camera = raylib.Camera{
		position,
		position + target,
		up,
		45.0,
		raylib.CameraProjection.PERSPECTIVE,
	}
	rock.materials[0].shader = default
	rock.materials[0].maps[raylib.MaterialMapIndex.ALBEDO].texture = rock_texture
	rock.materials[0].maps[raylib.MaterialMapIndex.NORMAL].texture = rock_normal

	build_rocks(&rng, -800, 800)

	lightPos := raylib.GetShaderLocation(default, "lightPos")
	light_pos := []f32{camera.position[0], camera.position[1], camera.position[2]}
	raylib.SetShaderValue(
		default,
		raylib.ShaderLocationIndex(lightPos),
		raw_data(light_pos),
		raylib.ShaderUniformDataType.VEC3,
	)

	// itime := f32(raylib.GetTime())

	status_buffer: [2048]byte
	scratch: mem.Scratch_Allocator
	mem.scratch_allocator_init(&scratch, 4096)
	sa := mem.scratch_allocator(&scratch)
	display_stats := true

	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.Q) do break

		if raylib.IsKeyPressed(raylib.KeyboardKey.P) do display_stats = !display_stats

		raylib.BeginDrawing()
			update_camera()
			camera.position = position
			camera.target = position + target
			camera.up = up
			raylib.ClearBackground(raylib.BLACK)
			raylib.BeginMode3D(camera) // Begin 3d mode drawing
				for i := 0; i < total_rocks; i += 1 {
					draw_rock(i)
					update_rock(i)
				}
				raylib.DrawSphere(center, 5, raylib.GREEN)
				raylib.DrawRay(raylib.Ray{direction = up, position = position + target}, raylib.YELLOW)
			raylib.EndMode3D() // End 3d mode drawing, returns to orthographic 2d mode
			if display_stats {
				cs := strings.clone_to_cstring(
					s = fmt.bprintf(
						status_buffer[:],
						"left_right_speed: %v - up_down_speed: %v",
						left_right_speed,
						up_down_speed,
					),
					allocator = sa,
				)
				raylib.DrawText(cs, 10, 10, 20, raylib.WHITE)
				free_all(sa)
				cs = strings.clone_to_cstring(
					s = fmt.bprintf(status_buffer[:], "target: %v", target),
					allocator = sa,
				)
				raylib.DrawText(cs, 10, 30, 20, raylib.WHITE)
				free_all(sa)
				cs = strings.clone_to_cstring(
					s = fmt.bprintf(status_buffer[:], "position: %v", position),
					allocator = sa,
				)
				raylib.DrawText(cs, 10, 50, 20, raylib.WHITE)
				free_all(sa)
				cs = strings.clone_to_cstring(
					s = fmt.bprintf(status_buffer[:], "up: %v", up),
					allocator = sa,
				)
				raylib.DrawText(cs, 10, 70, 20, raylib.WHITE)
				free_all(sa)
			}
		raylib.EndDrawing()
	}

	raylib.UnloadShader(default)
	raylib.UnloadTexture(rock_normal)
	raylib.UnloadTexture(rock_texture)
	raylib.UnloadModel(rock)
	raylib.CloseWindow()
}
