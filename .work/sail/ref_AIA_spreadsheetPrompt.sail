"Attributes to extract: 

" &
joinarray(
  a!forEach(
    items: ri!modelVersion['recordType!{f00f33ce-439e-4c81-9931-a244a643c0e8}AIA Extraction Model Version.relationships.{3e78fcff-a033-4b81-a754-e8fff1062c32}modelFields'],
    expression: concat(
      /*Field Key*/
      "- name: """ & fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key'] & """",
      /*Description*/
      if(
        a!isNotNullOrEmpty(fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ee728da9-1893-45c7-9d14-d2577b31d479}description']),
        ", description: """ & fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ee728da9-1893-45c7-9d14-d2577b31d479}description'] & """",
        {}
      ),
      /*Array distinguishment (for non-Tables only)*/
      if(
        fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{9212accc-6066-40ec-a480-a9eb98d3c46c}isMultiple'],
        ", it is an ARRAY",
        {}
      ),
      /*Column names for Tables & Large Tables*/
      if(
        or(
          fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{b7f55314-b6cd-432d-8772-3ce35eef1547}type'] = cons!AIA_EXTRACTION_FIELD_TYPE_TABLE,
          fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{b7f55314-b6cd-432d-8772-3ce35eef1547}type'] = cons!AIA_EXTRACTION_FIELD_TYPE_LARGE_TABLE
        ),
        concat(
          ", it is an ARRAY of OBJECTS (TABULAR) with the following attributes:",
          char(10),
          joinarray(
            a!forEach(
              items: fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.relationships.{604aeec7-e349-417e-adac-db2ec5f3999e}columns'],
              expression: concat(
                "        - name: """ & fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ed32edda-9ac0-476c-b19c-ec552b6452c4}key'] & """",
                if(
                  a!isNotNullOrEmpty(fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ee728da9-1893-45c7-9d14-d2577b31d479}description']),
                  ", description: """ & fv!item['recordType!{2838cbf2-2e48-4696-90bc-50ef0fca9ae9}AIA Extraction Model Version Field.fields.{ee728da9-1893-45c7-9d14-d2577b31d479}description'] & """",
                  {}
                )
              )
            ),
            char(10)
          )
        ),
        {}
      )
    )
  ),
  char(10)
)