grammar myCompiler;

options {
	language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
}

@members {
    boolean TRACEON = true;
    HashMap memory = new HashMap();
    
    public enum Type{
       ERR, BOOL, INT, FLOAT, CHAR, CONST_INT;
    }
    
    class tVar {
	   int   varIndex;
	   int   iValue;
	};

    class Info {
       Type theType;
       tVar theVar;
	   
	   Info() {
          theType = Type.ERR;
		  theVar = new tVar();
	   }
    };
    
    HashMap<String, Info> symtab = new HashMap<String, Info>();

    int labelCount = 0;
    
    int varCount = 0;

    int strCount = 0;

    List<String> TextCode = new ArrayList<String>();

    void prologue()
    {
       TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
       //TextCode.add("@str = private unnamed_addr constant [4 x i8] c\"\%d\\0A\\00\"");
       TextCode.add("define dso_local i32 @main()\n");
       TextCode.add("{\n");
    }

    void epilogue()
    {
       TextCode.add("ret i32 0\n");
       TextCode.add("}");
    	for (String i : TextCode) {
      		System.out.print(i);
    	}
    }

    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
    
    public List<String> getTextCode()
    {
       return TextCode;
    }
}

program:
	VOID MAIN{ prologue(); } '(' ')' '{' declarations stats '}'
	{  
           epilogue();
        };

declarations: type a=Identifier{
		Info the_entry = new Info();
		the_entry.theType = $type.attr_type;
		the_entry.theVar.varIndex = varCount;
		varCount ++;
		symtab.put($a.text, the_entry);
		if ($type.attr_type == Type.INT) { 
              		TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4\n");
           	}
	    } 
	    ('=' b=expr{
	    		Info theRHS = $b.theInfo;
			Info theLHS = symtab.get($a.text);
			if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)) {
                   		TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + "\n");} 
               	else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                   		TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + "\n");}
                 } )?
	    (',' c=Identifier{
			Info the_entryc = new Info();
			the_entryc.theType = $type.attr_type;
			the_entryc.theVar.varIndex = varCount;
			varCount ++;
			symtab.put($c.text, the_entryc);
			if ($type.attr_type == Type.INT) { 
              			TextCode.add("\%t" + the_entryc.theVar.varIndex + " = alloca i32, align 4\n");
           		}
		 } //entry entryc
	    ('=' d=expr{
			Info theRHS = $d.theInfo;
			Info theLHS = symtab.get($c.text);
			if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)) {
                   		TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + "\n");} 
               	else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                   		TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + "\n");}
                 } )? )* ';' declarations
           |
           ;

type
returns [Type attr_type]
    : INT { $attr_type=Type.INT; }
    ;

stats: stat stats
       |
       ;

stat:
	a=Identifier '=' b=expr {
		Info theRHS = $b.theInfo;
		Info theLHS = symtab.get($a.text);
		if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)) {
                   	TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + "\n");} 
               else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                   	TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + "\n");}
	  }';'
	| if_statement
	| print_statememt
	;

expr returns [Info theInfo]
@init {theInfo = new Info();}:
	a=multExpr {$theInfo=$a.theInfo;}
	( '+' b=multExpr {
		if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		} 
		else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	        else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	        else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	      }
	| '-' c=multExpr {
		if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		} 
		else if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
		else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	        else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + $c.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	      } )*
	;

multExpr  returns [Info theInfo]
@init {theInfo = new Info();}: 
          a=signExpr {$theInfo=$a.theInfo;}
	( '*' b=signExpr {
		if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		} 
		else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
		else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	        else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	      }
	| '/' c=signExpr {
		if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex + "\n"); 
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		} 
		else if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
		else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.INT)) {
               	TextCode.add("\%t" + varCount + " = sdiv nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	        else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.CONST_INT)) {
               	TextCode.add("\%t" + varCount + " = sdiv nsw i32 " + $theInfo.theVar.iValue + ", " + $c.theInfo.theVar.iValue + "\n");
               	$theInfo.theType = Type.INT;
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
		}
	      } )*
	;

signExpr returns [Info theInfo]
@init {theInfo = new Info();}: 
          a=atom {
          	$theInfo=$a.theInfo;
          } 
          | '-' b=atom {
          	$theInfo.theType=Type.INT;
          	if($b.theInfo.theType==Type.INT)
          		TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $b.theInfo.theVar.varIndex + ", -1"  + "\n");
          	else if($b.theInfo.theType==Type.CONST_INT)
          		TextCode.add("\%t" + varCount + " = mul nsw i32 " + $b.theInfo.theVar.iValue + ", -1" + "\n");
		$theInfo.theVar.varIndex = varCount;
          	varCount++;
	  };

logic_expression returns [Info theInfo]
@init {theInfo = new Info();}: 
          l=expr{
          	if($l.theInfo.theType == Type.INT){
          		TextCode.add( "\%t" + varCount + " = icmp ne i32 \%t" + $l.theInfo.theVar.varIndex + ", " + 0 + "\n");
          		$theInfo.theVar.varIndex = varCount;
          		$theInfo.theVar.iValue = labelCount;
          		$theInfo.theType = Type.BOOL;
          		varCount++;
          	}
          }
          (	LE r=expr {
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp slt i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp slt i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp slt i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp slt i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          	| GE r=expr {
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sgt i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sgt i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sgt i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sgt i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          	| LEQ r=expr {
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sle i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sle i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sle i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sle i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          	| GEQ r=expr {
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sge i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sge i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sge i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp sge i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          	| NE r=expr {
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp ne i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp ne i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp ne i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp ne i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          	| EQ r=expr{
          		$theInfo.theVar.varIndex = varCount;
          		if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp eq i32 \%t" + $l.theInfo.theVar.varIndex + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp eq i32 \%t" + $l.theInfo.theVar.varIndex + ", " + $r.theInfo.theVar.iValue + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp eq i32 " + $l.theInfo.theVar.iValue + ", \%t" + $r.theInfo.theVar.varIndex + "\n");
          		else if(($l.theInfo.theType == Type.CONST_INT) && ($r.theInfo.theType == Type.CONST_INT))
          			TextCode.add( "\%t" + $theInfo.theVar.varIndex + " = icmp eq i32 " + $l.theInfo.theVar.iValue + ", " + $r.theInfo.theVar.iValue + "\n");
          		varCount++;
          	}
          )?;

atom returns [Info theInfo]
@init {theInfo = new Info();}:
    Integer_constant {
    	$theInfo.theType = Type.CONST_INT;
	$theInfo.theVar.iValue =Integer.parseInt($Integer_constant.text);
    }
    |   Identifier{
	    Type the_type = symtab.get($Identifier.text).theType;
	    $theInfo.theType = the_type;
	    int vIndex = symtab.get($Identifier.text).theVar.varIndex;
	    TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex + "\n");
	    $theInfo.theVar.varIndex = varCount;
	    varCount++;
        }
    |   '(' a=expr ')' {
	    $theInfo=$a.theInfo;
	}
    ;

print_statememt:
	PRINTF '(' e=LETTERAL ',' 
		a=Identifier{
	    		int vIndex = symtab.get($a.text).theVar.varIndex;
	    		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex + "\n");
	    		varCount++;} ',' 
	    	b=Identifier{
	    		int vIndex = symtab.get($b.text).theVar.varIndex;
	    		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex + "\n");
	    		varCount++;} 
	    	')'';' {
	    		int len=$e.text.length();
	    		String tmp=new String();
	    		for(int i=1;i<len-1;i++){
	    			if($e.text.charAt(i)=='\\'){
	    				if($e.text.charAt(i+1)=='n') {
	    				tmp=tmp+"\\0A\\00";
	    				i++;}
	    			}
	    			else tmp=tmp + $e.text.charAt(i);
	    		}
	    		len=len-2;
	    		TextCode.add(1,"@str" + strCount + " = private unnamed_addr constant [" +len + " x i8] c\"" + tmp + "\"\n");
	    		TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" +len + " x i8], [" + len + " x i8]* @str" + strCount + ", i64 0, i64 0)");
	    		TextCode.add(", i32 \%t" + (varCount-2) + ", i32 \%t" + (varCount-1)+")\n");
	    		varCount++;
		}
	|PRINTF '(' e=LETTERAL ',' a=Identifier{
	    		int vIndex = symtab.get($a.text).theVar.varIndex;
	    		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex + "\n");
	    		varCount++;}  
	    	')'';' {
	    		int len=$e.text.length();
	    		String tmp=new String();
	    		for(int i=1;i<len-1;i++){
	    			if($e.text.charAt(i)=='\\'){
	    				if($e.text.charAt(i+1)=='n') {
	    				tmp=tmp+"\\0A\\00";
	    				i++;}
	    			}
	    			else tmp=tmp + $e.text.charAt(i);
	    		}
	    		len=len-2;
	    		TextCode.add(1,"@str" + strCount + " = private unnamed_addr constant [" +len + " x i8] c\"" + tmp + "\"\n");
	    		TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" +len + " x i8], [" + len + " x i8]* @str" + strCount + ", i64 0, i64 0)");
	    		TextCode.add(", i32 \%t" + (varCount-1)+")\n");
	    		varCount++;
		}
	|PRINTF '(' e=LETTERAL ')'';' {
	    		int len=$e.text.length();
	    		String tmp=new String();
	    		for(int i=1;i<len-1;i++){
	    			if($e.text.charAt(i)=='\\'){
	    				if($e.text.charAt(i+1)=='n') {
	    				tmp=tmp+"\\0A\\00";
	    				i++;}
	    			}
	    			else tmp=tmp + $e.text.charAt(i);
	    		}
	    		len=len-2;
	    		TextCode.add(1,"@str" + strCount + " = private unnamed_addr constant [" +len + " x i8] c\"" + tmp + "\"\n");
	    		TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" +len + " x i8], [" + len + " x i8]* @str" + strCount + ", i64 0, i64 0))\n");
	    		strCount++;
	    		varCount++;
		};

if_statement returns [Info theInfo]: 
        IF '(' e=logic_expression{ 
            int l1=$e.theInfo.theVar.iValue;
            int l2=l1+1;
            TextCode.add("br i1 \%t" + $e.theInfo.theVar.varIndex + ", label \%L" + l1 + ", label \%L" + l2 + "\n");
            TextCode.add("L" + l1 + ":\n");
            labelCount=labelCount+3;
        } ')' 
        if_stat {
        	int l1=$e.theInfo.theVar.iValue;
            	int l2=l1+1,lend=l1+2;
        	TextCode.add("br label \%L" + lend + "\n");
        	TextCode.add("L" + l2 + ":\n");
        }
	((ELSE) => ELSE if_stat)? {
		int l1=$e.theInfo.theVar.iValue;
            	int l2=l1+1,lend=l1+2;
		TextCode.add("br label \%L" + lend + "\n");
		TextCode.add("L" + lend + ":\n");
	}
	;
	
if_stat: stat | '{' stat '}';

/* description of the tokens */
INT: 'int';
MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';

PRINTF: 'printf';
Identifier: ('a' ..'z' | 'A' ..'Z' | '_') (
		'a' ..'z'
		| 'A' ..'Z'
		| '0' ..'9'
		| '_'
	)*;
Integer_constant: '0' ..'9'+;
INT_PUT: '%d';
WS: ( ' ' | '\t' | '\r' | '\n') {$channel=HIDDEN;};
COMMENT: '/*' .* '*/' {$channel=HIDDEN;};
TITLE: ('a' ..'z' | 'A' ..'Z')*('.h');

//  logic operator
LE: '<';
GE: '>';
LEQ: '<=';
GEQ: '>=';
NE: '!=';
EQ: '==';

//  special character
LETTERAL: '"' (~'"')* '"' ;
