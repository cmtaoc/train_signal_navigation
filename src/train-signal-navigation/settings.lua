data:extend({
	{
		type = "bool-setting",
		name = "nav-train-signal-mode",
		setting_type = "startup",
		default_value = false,
		description = "Test"
	},
	{
		type = "string-setting",
		name = "nav-train-signal-mode",
		setting_type = "startup",
		default_value = "A",
		allowed_values = {"A", "B"},
		description = "Signal station working mode."
	},
	{
		type = "bool-setting",
		name = "nav-train-signal-auto-created",
		setting_type = "runtime-global",
		default_value = false,
		description = "Automatically assigned to the supply station when a train with cars is created"
	},
	{
		type = "bool-setting",
		name = "nav-train-signal-out-signal",
		setting_type = "runtime-global",
		default_value = false,
		description = "Controller output signal, material itself or green signal with index, default material itself."
	},
	{
		type = "string-setting",
		name = "nav-train-signal-supply-name",
		setting_type = "runtime-global",
		auto_trim = true,
		default_value = "Supply",
		description = "Specific name of the supply station. the supply station shall be named by ‘material’ and specific name."
	}
})
