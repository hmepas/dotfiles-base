import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const key = "openai-fast";

function supportsFast(model: ExtensionContext["model"]) {
	return model?.provider === "openai-codex" ||
		(model?.provider === "openai" && model.api === "openai-responses");
}

export default function (pi: ExtensionAPI) {
	let enabled = true;

	function updateStatus(ctx: ExtensionContext, model = ctx.model) {
		if (!ctx.hasUI) return;
		const label = enabled ? ctx.ui.theme.fg("success", "Fast mode: ON") : "Fast mode: OFF";
		ctx.ui.setStatus(key, supportsFast(model) ? label : undefined);
	}

	pi.on("session_start", (_event, ctx) => {
		enabled = true;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === key && typeof entry.data?.enabled === "boolean") {
				enabled = entry.data.enabled;
			}
		}
		updateStatus(ctx);
	});

	pi.on("model_select", (event, ctx) => updateStatus(ctx, event.model));

	pi.registerCommand("fast", {
		description: "Toggle OpenAI priority for this session, or use /fast on, off, or status",
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase();
			if (action && action !== "on" && action !== "off" && action !== "status") {
				ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
				return;
			}
			if (action !== "status") {
				const next = action ? action === "on" : !enabled;
				if (next !== enabled) {
					enabled = next;
					pi.appendEntry(key, { enabled });
				}
			}
			updateStatus(ctx);
			const note = supportsFast(ctx.model) ? "" : " (not applied to the current model)";
			ctx.ui.notify(`Fast mode: ${enabled ? "ON" : "OFF"}${note}`, "info");
		},
	});

	pi.on("before_provider_request", (event, ctx) => {
		if (!enabled || !supportsFast(ctx.model)) return;
		const payload = event.payload;
		if (!payload || typeof payload !== "object" || Array.isArray(payload)) return;
		return { ...payload, service_tier: "priority" };
	});
}
