Pseudocode:

Delfos.log_call_site(call_site)
  new stack if no stack

  push call site onto stack
    call_site_logger.log(call_site, stack_uuid, stack_step)
      neo4j_realtime
        ```
        MERGE(call_stack:CallStack{uuid: {stack_uuid}})
        ```

        ```
        CREATE(call_site:CallSite{file: {file}, {line_number: line_number}})
        (call_stack)-[:STEP{number: {stack_step}}]->(call_site)
        ```

        flush if need to?

      neo4j_offline
        write queries to file
          ```
          MERGE(call_stack:CallStack{uuid: {stack_uuid}})
          ```

          ```
          CREATE(call_site:CallSite{file: {file}, {line_number: line_number}})
          (call_stack)-[:STEP{number: {stack_step}}]->(call_site)
          ```

        execute offline


  on pop at end of stack
    reset stack (and UUID)

  execute update distance

