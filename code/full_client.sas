/* The full code required for the API client. */

/* Create a file handle and ensure it is fresh. */
%macro FileHandle(handle, location=TEMP);
    filename &handle. clear; /* Will give warning on first invocation. */
    filename &handle. &location.;
%mend;

/* Read the contents of a file into a macro variable. */
%macro FileContents(variable_name, file_location);
    data _null_;
        infile &file_location. length=len;
        input contents $varying2000. len;
        call symputx(&variable_name., contents);
    run;
%mend;

%macro build_request(
    /* Required parameters: */
    data,
    request_handle,

    /* Optional parameters: */
    model="gpt-4o-mini",
    request_location=TEMP
);
    %FileHandle(&request_handle., location=&request_location.);
    data _null_;
        file &request_handle.;

        /* Write the opening of the JSON payload. */
        put '{';
        put     '"model": "' &model. '",';
        put     '"messages": [';

        /* Loop through the dataset and construct each message block. */
        do i = 1 by 1 until (eof);
            set &data end=eof;
            
            /* Escape quotation marks. */
            length esc_text $4000;
            esc_text = tranwrd(text, '"', '\"');

            /* Begin the message object */
            put '{';
            put     '"role": "' role +(-1) '",';
            put     '"content": [';
            put         '{ "type": "text", "text": "' esc_text +(-1) '" }';
            put     ']';

            /* End the message object */
            if eof then put '}';
            else put '},';
        end;

        /* Close the messages array and the JSON object */
        put     ']';
        put '}';
        stop;
    run;
%mend;

%macro send_request(
    /* Required parameters */
    request_handle,
    response_handle,
    api_key_location,

    /* Optional parameters */
    service=openai, /* Can pass "deepseek" instead with no other changes. */
    response_location=TEMP
);
    %local api_key;
    %FileContents("api_key", &api_key_location.);
    %FileHandle(&response_handle., location=&response_location.);

    /* Make the request. This may take a few seconds to complete. */
    proc http
        url = "https://api.&service..com/v1/chat/completions"
        method = "POST"
        ct = "application/json"
        in = &request_handle.
        out = &response_handle.;
        
        headers "Authorization" = "Bearer &api_key.";
    run;

    /* Results are now stored in response_handle! */

%mend;

%macro Prompt(name, contents);
    data &name.;
        length role $20 text $2000;
        retain i 1;
        do while(scan("&contents.", i, '~') ne '');
            line = scan("&contents.", i, '~');
            role = scan(line, 1, '|');
            text = scan(line, 2, '|');
            output;
            i + 1;
        end;
        drop i line;
    run;
%mend;

/* Thanks to Stephen Mc Cawille ("Getting a Prompt Response Using ChatGPT and SAS") for this code. */
%macro extract_response(dataset_name, response_handle, temp_library_handle);
    libname &temp_library_handle. JSON fileref = &response_handle.;

    data &dataset_name.;
        set &temp_library_handle..choices_message;
        output;
        /*
        do row = 1 to max(1, countw(content, '0A'x));
            outvar = scan(content, row, '0A'x);
            output;
        end;
        */
    run;
%mend;

/* Fully process a raw prompt into a response message. */
%macro send_prompt(
    /* Required Parameters: */
    message_handle,
    prompt,
    
    /* Optional Parameters: */
    model="gpt-4o-mini",
    api_key_location="sources/api_key_chatgpt.txt",
    service=openai
);
    %Prompt(temp_prompt_data, &prompt.);
    %build_request(temp_prompt_data, tempreq, model=&model.);
    %send_request(tempreq, tempresp, &api_key_location., service=&service.);
    %extract_response(&message_handle., tempresp, templib);
%mend;

/* Test apparatus */
%macro send_multiple_prompts(output_ds, system_prompt=, user_prompts=);

    /* Clean up the output dataset if it exists */
    proc datasets lib=work nolist;
        delete &output_ds;
    quit;

    %let i = 1;
    %let single_prompt = %scan(&user_prompts, &i, |);

    %do %while(%length(&single_prompt));

        /* Build the full prompt for this iteration */
        %let full_prompt = &system_prompt.&single_prompt;

        /* Temporary dataset for each iteration */
        %let temp_ds = _tmp_resp_&i;

        %put &full_prompt.;

        /* Call the existing %send_prompt macro */
        %send_prompt(&temp_ds, %superq(full_prompt));

        /* Add a variable for the user prompt */
        data &temp_ds;
            length user_prompt $2000;
            set &temp_ds;
            user_prompt = "&single_prompt";
        run;

        /* Append this result to the master output dataset */
        %if &i = 1 %then %do;
            data &output_ds;
                length user_prompt $2000 content $2000;
                set &temp_ds;
                keep user_prompt content;
            run;
        %end;
        %else %do;
            proc append base=&output_ds data=&temp_ds force; run;
        %end;

        /* Move to the next prompt */
        %let i = %eval(&i + 1);
        %let single_prompt = %scan(&user_prompts, &i, |);

    %end;

    /* Reorder for clarity: user prompt first, then response */
    data &output_ds;
        retain user_prompt;
        set &output_ds;
    run;

%mend;
