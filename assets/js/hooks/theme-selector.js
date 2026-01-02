export default {
	mounted() {
		this.updateButtonStates();

		this.handleThemeChange = () => {
			this.updateButtonStates();
		};

		window.addEventListener("storage", this.handleThemeChange);
		window.addEventListener("phx:set-theme", this.handleThemeChange);

		const observer = new MutationObserver(() => {
			this.updateButtonStates();
		});

		observer.observe(document.documentElement, {
			attributes: true,
			attributeFilter: ["data-theme"],
		});

		this.observer = observer;
	},

	updateButtonStates() {
		const currentTheme =
			document.documentElement.getAttribute("data-theme") || "system";
		const buttons = this.el.querySelectorAll("button[data-phx-theme]");

		buttons.forEach((button) => {
			const buttonTheme = button.getAttribute("data-phx-theme");
			const isActive = buttonTheme === currentTheme;

			if (isActive) {
				button.classList.add(
					"!border-blue-500",
					"!bg-blue-50",
					"dark:!bg-blue-900/20"
				);
			} else {
				button.classList.remove(
					"!border-blue-500",
					"!bg-blue-50",
					"dark:!bg-blue-900/20"
				);
			}
		});
	},

	destroyed() {
		window.removeEventListener("storage", this.handleThemeChange);
		window.removeEventListener("phx:set-theme", this.handleThemeChange);
		if (this.observer) {
			this.observer.disconnect();
		}
	},
};
