var $toggle = document.getElementById("unit-toggle");

function toggleUnits() {
  var selected = $toggle.checked;
  if (selected) {
    document.body.classList.add("metric");
  } else {
    document.body.classList.remove("metric");
  }
}

$toggle.addEventListener("change", () => {
  toggleUnits();
  localStorage.setItem(
    "preferredUnits",
    $toggle.checked ? "metric" : "imperial",
  );
});

window.addEventListener("DOMContentLoaded", (event) => {
  const userLang = navigator.language || navigator.userLanguage;
  const preferredUnits = localStorage.getItem("preferredUnits");

  if (preferredUnits) {
    console.log("preferred units", preferredUnits);
    $toggle.checked = preferredUnits === "metric";
  } else if (userLang === "en-US") {
    $toggle.checked = false;
  } else {
    $toggle.checked = true;
  }

  toggleUnits();
});
