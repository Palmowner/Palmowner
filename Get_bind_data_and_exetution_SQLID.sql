begin
    execute immediate('SELECT /*+ INDEX(DEPOSIT.XIE2DEPOHIST) */ OPTRANSDAY FROM DEPOSIT.DEPOHIST WHERE ID_MEGA=:B5 AND DEPOSIT_MINOR=:B4 AND DEPOSIT_MAJOR=:B3 AND OPTRANSDAY>=:B2 AND OPTRANSDAY< :B1 +1 AND STATE<>5 AND (OPKIND=14 OR OPKIND=15) ORDER BY OPTRANSDAY DESC') using 16,7346,18612267,TO_DATE('10/03/2023 00:00:00','MM/DD/YYYY HH24:MI:SS'),TO_DATE('10/03/2023 00:00:00','MM/DD/YYYY HH24:MI:SS');
end;

declare
  c_sql_fulltext clob;
  sql_fulltext varchar(32767);
  sql_fulltext_bind varchar(32767);
  value_string varchar(2048);
  bind_values varchar(32767);
  p_sql_id varchar(32):='46cvtapwd7rmb';
  isbindval int:=0; 

  function get_text_from_clob(p_clob in clob) return varchar2 is
    l_offset pls_integer:=1;
    l_line varchar2(32767);
    l_total_length pls_integer:=length(p_clob);
    l_line_length pls_integer;
    l_res varchar2(32767);

  begin
    l_res:='';
    while l_offset<=l_total_length loop
      l_line_length:=instr(p_clob,chr(10),l_offset)-l_offset;
      if l_line_length<0 then
        l_line_length:=l_total_length+1-l_offset;
      end if;

      l_line:=substr(p_clob,l_offset,l_line_length);
      l_res:=l_res||l_line;
      l_offset:=l_offset+l_line_length+1;
    end loop;
    return l_res;
  end get_text_from_clob;

begin

  select sql_fulltext into c_sql_fulltext from v$sql where sql_id = p_sql_id and rownum<=1;

  sql_fulltext:=get_text_from_clob(c_sql_fulltext);
  sql_fulltext_bind := sql_fulltext;

  for rec in (select name,value_string,datatype_string,position from v$sql_bind_capture where sql_id = p_sql_id and child_number in (select max(child_number) from v$sql_bind_capture where sql_id = p_sql_id) and was_captured = 'YES' order by case when isbindval = 1 then position else 0 end desc, case when isbindval = 1 then '' else name end desc) loop

    value_string:=rec.value_string;

    if rec.datatype_string like 'VARCHAR2%' then
       value_string:=''''||value_string||'''';
    elsif rec.datatype_string like 'DATE' then
       value_string:='TO_DATE('''||value_string||''',''MM/DD/YYYY HH24:MI:SS'')';
    end if;
    sql_fulltext:=replace(sql_fulltext,lower(rec.name),value_string);
    bind_values:=value_string || case when bind_values is null or bind_values = '' then '' else ',' end || bind_values;
  end loop;

  if isbindval = 1 then
    dbms_output.put_line('begin');
    dbms_output.put_line('  execute immediate(''' || sql_fulltext_bind || ''') using ' || bind_values || ';');
    dbms_output.put_line('end;');

  else
    dbms_output.put_line(sql_fulltext);
  end if;
end;
