function showHidden(event) {
  const toggleElement = event.currentTarget;
  const element = toggleElement.parentNode.querySelector(".custom-quota-div");
  element.hidden = false;
}

function hideCustomQuota() {
  const element = $(".storage-frame .custom-quota-div");
  element[0].hidden = true;
}

function selectStorage(event) {
  const storageElement = event.currentTarget;
  storageElement.querySelector("input").click();
}

// eslint-disable-next-line import/prefer-default-export
export function storageInputs() {
  $(".custom-quota-toggle").on("click", (event) => {
    showHidden(event);
  });

  $(".custom-quota-close").on("click", () => {
    hideCustomQuota();
  });

  $(".custom-quota-toggle").keyup((event) => {
    if (event.keyCode === 13) showHidden(event);
  });

  $(".custom-quota-close").keyup((event) => {
    if (event.keyCode === 13) hideCustomQuota();
  });

  $(".quota-option").keyup((event) => {
    if (event.keyCode === 13) selectStorage(event);
  });
}
