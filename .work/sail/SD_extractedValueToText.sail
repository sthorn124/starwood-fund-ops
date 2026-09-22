/* Draw approval (Phase 3): one extracted value as plain text, so typed Doc Center output can travel through JSON and
   process variables without loss. Dates become yyyy-MM-dd, numbers keep their full precision, nulls become "". */
a!localVariables(
  local!v: ri!value,
  if(
    a!isNullOrEmpty(local!v),
    "",
    a!localVariables(
      local!t: runtimetypeof(local!v),
      if(
        local!t = typeof(today()),
        text(local!v, "yyyy-MM-dd"),
        if(
          local!t = typeof(now()),
          text(todate(local!v), "yyyy-MM-dd"),
          if(
            or(local!t = typeof(1.5), local!t = typeof(1)),
            tostring(local!v),
            tostring(local!v)
          )
        )
      )
    )
  )
)
