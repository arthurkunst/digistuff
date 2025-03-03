local pplate_box_off = {
	type = "fixed",
    fixed = { -7/16, -8/16, -7/16, 7/16, -7/16, 7/16 },
}

local pplate_box_on = {
    type = "fixed",
    fixed = { -7/16, -8/16, -7/16, 7/16, -7.5/16, 7/16 },
}

local function obj_touching_plate_pos(obj_ref, plate_pos)
	local obj_pos = obj_ref:get_pos()
	local props = obj_ref:get_properties()
	if not (props and obj_pos and not obj_ref:get_attach()) then
		return false
	end

	local collisionbox = props.collisionbox
	local physical = props.physical
	local is_player = obj_ref:is_player()
	local luaentity = obj_ref:get_luaentity()
	local is_item = luaentity and luaentity.name == "__builtin:item"
	if not (collisionbox and physical or is_player or is_item) then
		return false
	end

	local plate_x_min = plate_pos.x - 7 / 16
	local plate_x_max = plate_pos.x + 7 / 16
	local plate_z_min = plate_pos.z - 7 / 16
	local plate_z_max = plate_pos.z + 7 / 16
	local plate_y_min = plate_pos.y - 8 / 16
	local plate_y_max = plate_pos.y - 6.5 / 16

	local obj_x_min = obj_pos.x + collisionbox[1]
	local obj_x_max = obj_pos.x + collisionbox[4]
	local obj_z_min = obj_pos.z + collisionbox[3]
	local obj_z_max = obj_pos.z + collisionbox[6]
	local obj_y_min = obj_pos.y + collisionbox[2]
	local obj_y_max = obj_pos.y + collisionbox[5]

	if
		obj_y_min < plate_y_max and
		obj_y_max > plate_y_min and
		obj_x_min < plate_x_max and
		obj_x_max > plate_x_min and
		obj_z_min < plate_z_max and
		obj_z_max > plate_z_min
	then
		return true
	end
	return false
end

local function pp_on_timer(pos) -- pressure plate timer function, call every 0.1 seconds
	local node = minetest.get_node(pos)
	local basename = "digistuff:pressureplate"

	-- This is a workaround for a strange bug that occurs when the server is started
	-- For some reason the first time on_timer is called, the pos is wrong
	if not basename then return end

	local objs = minetest.get_objects_inside_radius(pos, 1)
	local obj_touching = false
    local player_name = nil
	for k, obj in pairs(objs) do
		if obj_touching_plate_pos(obj, pos) then
			obj_touching = true
            if obj:is_player() then
                player_name = obj:get_player_name()
            end
			break
		end
	end

	if not obj_touching and node.name == basename .. "_pressed" then -- object left the plate
        node.name = basename
		minetest.swap_node(pos,node)
        minetest.sound_play("digistuff_piston_extend", {pos=pos})

	elseif obj_touching and node.name == basename then -- object entered the plate
		local meta = minetest.get_meta(pos)
        local channel = meta:get_string("channel")
        local msg = meta:get_string("msg")

        node.name = basename .. "_pressed"
		minetest.swap_node(pos,node)

        if player_name then -- object is a player
            digilines.receptor_send(pos, digistuff.button_get_rules(node), channel, {player_name, msg})
            minetest.sound_play("digistuff_piston_retract", {pos=pos})
        else -- object is not a player
            digilines.receptor_send(pos, digistuff.button_get_rules(node), channel, msg)
        end
	end
	return true
end


minetest.register_node("digistuff:pressureplate", {
    drawtype = "nodebox",
    tiles = {
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png"
    },
    node_box = pplate_box_off,
    selection_box = pplate_box_off,
    paramtype = "light",
    is_ground_content = false,
    description = "Digistuff Pressure Plate",
    on_timer = pp_on_timer,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.1) -- start timer with interval 0.1
        local meta = minetest.get_meta(pos)
		meta:set_string("formspec","size[7.5,3]field[1,0;6,2;channel;Channel;]field[1,1;6,2;msg;Message;]button_exit[2.25,2;3,1;submit;Save]")
    end,
    digiline =
    {
        receptor = {},
        wire = {
            rules = digistuff.button_get_rules,
        },
    },
    _digistuff_channelcopier_fieldname = "channel",
    groups = {dig_immediate = 2,digiline_receiver = 1,},
    on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
        
		if fields.submit then
			if fields.channel ~= "" then
				meta:set_string("channel",fields.channel)
				meta:set_string("msg",fields.msg)
                meta:set_string("formspec", "")
			else
				minetest.chat_send_player(sender:get_player_name(),"Please set a channel!")
			end
		end
	end,
})

minetest.register_node("digistuff:pressureplate_pressed", {
    drawtype = "nodebox",
    tiles = {
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png",
        "digistuff_digibutton_sides.png"
    },
    node_box = pplate_box_on,
    selection_box = pplate_box_on,
    paramtype = "light",
    is_ground_content = false,
    description = "Digistuff Pressure Plate pressed state",
    on_timer = pp_on_timer,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.1) -- start timer with interval 0.1
    end,
    digiline = {
        receptor = {},
        wire = {
            rules = digistuff.button_get_rules,
        },
        effector = {
            action = digistuff.button_handle_digilines,
        },
    },
    _digistuff_channelcopier_fieldname = "channel",
    groups = {dig_immediate = 2,not_in_creative_inventory = 1,digiline_receiver = 1,},
})