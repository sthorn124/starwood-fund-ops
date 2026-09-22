from refs import *
Dr = lambda n: fld(DRAW, n)

rows_rule = f"""/* Draw approval: the Draws list rows for the viewer, one map per draw, already sorted the way the
   Draws page shows them: draws awaiting the viewer's action first, then in-approval draws by funding date
   ascending, then completed draws by funding date descending. Each row is rule!SD_getDrawDetail's map plus
   a sort bucket, so the KPIs, the YOUR ACTION tag and the row highlight all come from the same read. */
a!localVariables(
  local!ids: a!queryRecordType(
    recordType: {rt(DRAW)},
    fields: {{ {Dr("id")} }},
    pagingInfo: a!pagingInfo(startIndex: 1, batchSize: 200, sort: a!sortInfo(field: {Dr("drawNumber")}, ascending: false))
  ).data[{Dr("id")}],
  local!rows: a!forEach(
    items: local!ids,
    expression: a!localVariables(
      local!d: rule!SD_getDrawDetail(drawId: fv!item),
      local!status: tostring(a!defaultValue(index(local!d, "status", ""), "")),
      local!fd: index(local!d, "fundingDate", null),
      a!update(
        local!d,
        {{"bucket", "sortAll"}},
        a!localVariables(
          local!bucket: if(a!defaultValue(index(local!d, "awaitingViewer", false), false), 1, if(local!status = "In Progress", 2, 3)),
          /* days since 2000-01-01; negated for completed draws so ascending order puts the latest funding first */
          local!key: if(
            a!isNullOrEmpty(local!fd),
            0,
            if(local!bucket = 3, -tointeger(todate(local!fd) - date(2000, 1, 1)), tointeger(todate(local!fd) - date(2000, 1, 1)))
          ),
          {{local!bucket, local!bucket * 100000 + local!key + 50000}}
        )
      )
    )
  ),
  /* one ascending sort on the composite key: bucket first, then funding date in the direction the bucket wants */
  todatasubset(local!rows, a!pagingInfo(startIndex: 1, batchSize: -1, sort: a!sortInfo(field: "sortAll", ascending: true))).data
)
"""
open("SD_getDrawListRows.sail","w").write(rows_rule)
print("rows rule written")
