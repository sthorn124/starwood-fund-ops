/* Draw approval (Phase 4): text made safe for an HTML email body — &, < and > escaped; null becomes "". */
substitute(substitute(substitute(a!defaultValue(tostring(ri!text), ""), "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
