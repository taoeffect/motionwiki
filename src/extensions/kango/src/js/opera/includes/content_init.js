kango.DelayedInitEnd=function(){"complete"==document.readyState?(kango._init("document-end"),kango.FireDOMContentLoadedEvent()):window.setTimeout(kango.DelayedInitEnd,50)};kango._init("document-start");"complete"==document.readyState||"interactive"==document.readyState?kango.DelayedInitEnd():window.addEventListener("DOMContentLoaded",kango.DelayedInitEnd,!1);
