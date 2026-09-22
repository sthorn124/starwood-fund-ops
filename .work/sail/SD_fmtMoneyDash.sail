/* Draw approval (Phase 4): whole-dollar money for the email tables, an em dash for null or zero (the sample's convention). */
if(a!isNullOrEmpty(ri!value), "—", if(ri!value = 0, "—", rule!SD_fmtMoney(value: ri!value, showCents: false)))
