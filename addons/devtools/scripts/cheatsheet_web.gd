extends Node


const WEB_ROOT := "res://addons/devtools/web/dist"


signal updated_commands_json()


var commands_json := ""
var invalid_commands_json = true
var commands_json_mutex := Mutex.new()


func _ready() -> void:
	DevTools.command_registered.connect(func(): invalid_commands_json = true, Node.CONNECT_DEFERRED)


func start() -> void:
	var file_router := HttpFileRouter.new("/*", WEB_ROOT)
	
	# simple get request
	# you can do other options like "post" and "delete" and so on
	var simpleroute := HttpRouter.new("/", {
		"get": func(request: HttpRequest, response: HttpResponse):
			response.send(200, "hello world")
			return true
	})
	
	var server = HttpServer.new()
	server.server_identifier = "DevTools for " + ProjectSettings.get_setting_with_override("application/config/name")
	server.register_router(file_router)
	server.register_router(HttpRouter.new("/execute", {
		"post": func(request: HttpRequest, response: HttpResponse):
			var command_id := request.body
			if command_id.is_empty():
				response.send(400, "No command id specified!")
				return
			
			var execute_hidden := command_id.begins_with(" ")
			command_id = command_id.strip_edges()
			
			print("[DevTools] Executing remote command ", command_id)
			
			var command: DEV_Command = DevTools.commands_by_id.get(command_id)
			if command:
				DevTools.run_command(command, execute_hidden)
				response.send(200, "Ok")
			else:
				response.send(404, "Command Not Found")
			return true
	}))
	server.register_router(HttpRouter.new("/commands", {
		"get": func(request: HttpRequest, response: HttpResponse):
			if invalid_commands_json:
				invalid_commands_json = false
				update_commands_json()
			
			commands_json_mutex.lock()
			return commands_json
			commands_json_mutex.unlock()
			pass
	}))
	
	add_child(server)
	
	server.start()


func update_commands_json() -> void:
	var thread := Thread.new()
	thread.start(_update_commands_json_threaded.bind(DevTools.commands_by_id))


func _update_commands_json_threaded(commands_by_id: Dictionary[StringName, DEV_Command]) -> void:
	var data: Array[Dictionary] = []
	for command: DEV_Command in commands_by_id.values():
		data.append({
			"id": command.id,
			"name": command.name,
			"description": command.description,
			"parameters": command.parameters,
		})
	
	var json := JSON.stringify(data)
	
	commands_json_mutex.lock()
	commands_json = json
	commands_json_mutex.unlock()
	
	updated_commands_json.emit.call_deferred()
