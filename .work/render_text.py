import json,sys
j=json.load(open(sys.argv[1]))
out=[]
SKIP={"COLLAPSED","NONE","STANDARD","LESS","EVEN_LESS","MORE","ABOVE","START","END","CENTER","RIGHT","LEFT","MIDDLE","TOP","AUTO","DENSE","LIGHT","THIN","SMALL","MEDIUM","STRONG","PLAIN","POSITIVE","SEMI_ROUNDED","NARROW","NARROW_PLUS","MEDIUM_PLUS","ROUNDED","STANDALONE","INLINE"}
def walk(n):
    if isinstance(n,dict):
        for k,v in n.items():
            if k in ("text","label","emptyGridMessage","percentage","altText","name"):
                if isinstance(v,list):
                    s="".join(str(x) for x in v if isinstance(x,(str,int,float))).strip()
                    if s: out.append(s)
                elif isinstance(v,(str,int,float)):
                    s=str(v).strip()
                    if s and s not in SKIP: out.append(s)
            elif k=="value" and isinstance(v,(str,int,float)):
                s=str(v).strip()
                if s and s not in SKIP: out.append(s)
            else: walk(v)
    elif isinstance(n,list):
        for x in n: walk(x)
walk(j.get("result",j))
print(" | ".join(out))
print("\nDIAG:", j.get("diagnostics"))
