/* Draw approval: the fact strip under the record header on every draw view — Draw #, Amount, Status,
   Funding Date (with the computed "in N days"), Draw Type, Fund. ri!detail is rule!SD_getDrawDetail's map. */
a!localVariables(
  local!d: ri!detail,
  local!found: a!defaultValue(index(local!d, "found", false), false),
  local!statusText: tostring(a!defaultValue(index(local!d, "status", ""), "")),
  local!role: index(local!d, "currentRole", null),
  local!fundingDate: index(local!d, "fundingDate", null),
  a!cardLayout(
    contents: {
      a!richTextDisplayField(
        labelPosition: "COLLAPSED",
        value: {
          a!richTextItem(text: "Draws › ", color: "#6B7280", size: "SMALL"),
          a!richTextItem(text: "Draw #" & a!defaultValue(index(local!d, "drawNumber", "?"), "?"), color: "#16294D", size: "SMALL", style: "STRONG")
        },
        marginBelow: "LESS"
      ),
      a!columnsLayout(
        columns: {
          a!columnLayout(
            contents: rule!SD_cmp_labelValue(
              label: "Amount",
              value: rule!SD_fmtMoney(value: index(local!d, "amount", null), showCents: true),
              emphasize: true,
              marginBelow: "NONE"
            ),
            width: "AUTO"
          ),
          a!columnLayout(
            contents: {
              a!richTextDisplayField(
                labelPosition: "COLLAPSED",
                value: a!richTextItem(text: "STATUS", color: "#6B7280", size: "SMALL"),
                marginBelow: "EVEN_LESS"
              ),
              a!sideBySideLayout(
                items: {
                  a!sideBySideItem(item: rule!SD_cmp_statusTag(status: local!statusText), width: "MINIMIZE"),
                  a!sideBySideItem(
                    item: a!richTextDisplayField(
                      labelPosition: "COLLAPSED",
                      value: a!richTextItem(
                        text: if(
                          and(local!statusText = "In Progress", not(a!isNullOrEmpty(local!role))),
                          "— " & local!role,
                          ""
                        ),
                        color: "#16294D"
                      )
                    ),
                    width: "AUTO"
                  )
                },
                alignVertical: "MIDDLE",
                spacing: "DENSE",
                marginBelow: "NONE"
              )
            },
            width: "AUTO"
          ),
          a!columnLayout(
            contents: a!richTextDisplayField(
              labelPosition: "COLLAPSED",
              value: {
                a!richTextItem(text: "FUNDING DATE", color: "#6B7280", size: "SMALL"),
                char(10),
                a!richTextItem(
                  text: if(a!isNullOrEmpty(local!fundingDate), "—", text(local!fundingDate, "MMMM D, YYYY")),
                  size: "MEDIUM",
                  style: "STRONG",
                  color: "#16294D"
                ),
                char(10),
                a!richTextItem(
                  text: rule!SD_fmtRelativeDays(days: index(local!d, "daysToFunding", null)),
                  color: "#1D5BBF",
                  size: "SMALL"
                )
              },
              marginBelow: "NONE"
            ),
            width: "AUTO"
          ),
          a!columnLayout(
            contents: rule!SD_cmp_labelValue(label: "Draw Type", value: index(local!d, "drawType", null), marginBelow: "NONE"),
            width: "AUTO"
          ),
          a!columnLayout(
            contents: rule!SD_cmp_labelValue(label: "Fund", value: index(local!d, "fundName", null), marginBelow: "NONE"),
            width: "AUTO"
          )
        },
        stackWhen: {"PHONE", "TABLET_PORTRAIT"},
        spacing: "STANDARD",
        marginBelow: "NONE"
      )
    },
    showWhen: local!found,
    style: "NONE",
    shape: "SEMI_ROUNDED",
    padding: "STANDARD",
    showBorder: true,
    showShadow: false,
    marginBelow: "STANDARD"
  )
)
