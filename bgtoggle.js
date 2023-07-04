function toggleStyles() {
    var body = document.body;

    // Check if element has styleA
    if (body.classList.contains("body")) {
        body.classList.remove("body");
        body.classList.add("alt-body");
        localStorage.setItem("toggleState", "alt-body");
    } else {
        body.classList.remove("alt-body");
        body.classList.add("body");
        localStorage.setItem("toggleState", "body");
    }
}
window.addEventListener("DOMContentLoaded", function () {
    var toggleState = localStorage.getItem("toggleState");
    if (toggleState === "alt-body") {
        document.body.classList.remove("body")
        document.body.classList.add("alt-body");
    } else {
        document.body.classList.remove("alt-body")
        document.body.classList.add("body");
    }
});

