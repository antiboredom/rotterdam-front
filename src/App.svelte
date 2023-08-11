<script>
  import FIELDS from "./fields.js";
  import Field from "./Field.svelte";
  import { userFields, highlightedField } from "./stores.js";
  // import TextExplain from "./TextExplain.svelte";
  import TextTree from "./TextTree.svelte";
  import TextBlock from "./TextBlock.svelte";
  import Tree from "./Tree.svelte";
  import TREES from "./trees.json";
  import { fade } from "svelte/transition";
  import LazyLoad from "@dimfeld/svelte-lazyload";
  import archetypes from "./archetypes.json";
  import { t } from "./i18n";

  const params = new URLSearchParams(window.location.search);
  const EXTERNAL = params.get("css") !== null;

  const dev = false;
  const APIURL = dev ? "http://localhost:8080/" : "https://rotterdam-model.fly.dev/";
  const AUTH = dev ? "" : "uApjBhZ4w6h2aFQp3nx9gQFfwnJGxqoaEGeeof7H";
  const trees = TREES.trees;

  const featureKey = {};

  for (const f of FIELDS) {
    featureKey[f.feature_dutch_underscore] = f.index;
  }

  const sorters = {
    alphabetical: (a, b) =>
      a.feature_english_auto_translate
        .toLowerCase()
        .localeCompare(b.feature_english_auto_translate.toLowerCase()),
    importance: (a, b) => b.feature_importance - a.feature_importance,
    index: (a, b) => a.index - b.index,
  };

  let score = 0;
  let loading = false;
  let sort = "index";
  let show = "all";
  let explainView = "poem";
  let treeIndex = 499;
  let fieldElements = [];
  let showCategories = false;
  let categories = [];
  let showAbout = false;

  const scorePosition = params.get("score") == "left" ? "left" : "right";

  let categoryNames = [...new Set(FIELDS.map((f) => f.category.toLowerCase()))].sort();
  // let categories = FIELDS.map(f => f.category)

  let sortedFields = [...FIELDS].sort(sorters[sort]);
  onResetValues();
  onFilter();

  function onSort() {
    sortedFields = [...sortedFields].sort(sorters[sort]);
    setCategories();
  }

  function onFilter() {
    if (show == "all") {
      sortedFields = [...FIELDS].sort(sorters[sort]);
    } else {
      sortedFields = FIELDS.filter((f) => f.feature_importance > 1);
      onSort();
    }
    setCategories();
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async function autoRun() {
    onResetValues();
    let oldFields = $userFields;
    for (let i = 0; i < $userFields.length; i++) {
      const f = FIELDS[i];
      if (f.feature_importance <= 1 && show == "importance") {
        continue;
      }
      let newVal;
      if (f.type == "boolean") {
        // newVal =  Math.random() < 0.5 ? 0.0 : 1.0;
        newVal = oldFields[i] == 1.0 ? 0.0 : 1.0;
      } else if (f.type == "float") {
        newVal = +(Math.random() * f.maxval).toFixed(1);
      } else {
        newVal = parseInt(Math.random() * f.maxval);
      }
      highlightedField.set(f.index);
      await sleep(1000);
      oldFields[i] = newVal;
      userFields.set(oldFields);
      await sleep(500);
      await onSubmit();
    }
    highlightedField.set(-1);
  }

  setTimeout(() => {
    autoRun();
  }, 1000);

  function onRandomize() {
    // randomizing = true;
    // console.log(fieldElements);
    // for (let f of fieldElements) {
    //   f.animate();
    // }
    // setTimeout(() => {
    userFields.set(
      FIELDS.map((f) => {
        if (f.type == "boolean") {
          return Math.random() < 0.5 ? 0.0 : 1.0;
        } else if (f.type == "float") {
          return +(Math.random() * f.maxval).toFixed(1);
        } else {
          return parseInt(Math.random() * f.maxval);
        }
      })
    );
    // }, 300);
    setCategories;
  }

  function onResetValues() {
    userFields.set(FIELDS.map((f) => f.default_value));
  }

  function onArchetype(a) {
    // let newVals = [];
    // for (let k of Object.keys(a.values)) {
    //   let val = a.values[k];
    //   let i = featureKey[k]
    //   console.log(i, val)
    // }
    let newVals = Object.keys(a.values).map((k) => {
      return a.values[k];
    });
    userFields.set(newVals);
  }

  function setCategories() {
    categories = categoryNames.map((c) => {
      return { name: c, fields: sortedFields.filter((f) => f.category.toLowerCase() == c) };
    });
  }

  async function onSubmit(e) {
    document.querySelectorAll("main section")[1].scrollIntoView({ behavior: "smooth" });
    loading = true;
    let data = { auth: AUTH, d: [$userFields] };
    let response = await fetch(APIURL, {
      method: "POST",
      body: JSON.stringify(data),
      headers: {
        "Content-Type": "application/json",
      },
    });
    let results = await response.json();
    score = results[0]["Ja"];
    loading = false;
  }

  function toggleAbout() {
    showAbout = !showAbout;
  }
</script>

<main>
  <section>
    <!-- <header> -->
    <!-- {#if !EXTERNAL} -->
    <!--   <div class="header-top"> -->
    <!--     <h1>Rotterdam Risk Score Calculator</h1> -->
    <!--   </div> -->
    <!--   <div class="break" /> -->
    <!--   <p> -->
    <!--     The risk score calculator lets you run the machine learning model that the city of -->
    <!--     Rotterdam uses to automate risk assessments for citizens seeking government services. The -->
    <!--     form below contains all the fields that are used as inputs to the model. <a -->
    <!--       href="#about" -->
    <!--       on:click|preventDefault={toggleAbout}>Learn more.</a -->
    <!--     > -->
    <!--   </p> -->
    <!-- {:else} -->
    <!--   <h2>{t("data_input")}</h2> -->
    <!--   <p>{t("enter_your_data")}</p> -->
    <!-- {/if} -->
    <!-- </header> -->
    <article>
      <form on:submit|preventDefault={onSubmit}>
        {#if showCategories}
          {#each categories as cat}
            {#if cat.fields.length > 0}
              <fieldset>
                <legend class="cat-name">{t(cat.name)}</legend>
                <div class="fields">
                  {#each cat.fields as field, index}
                    <Field {...field} bind:this={fieldElements[index]} />
                  {/each}
                </div>
              </fieldset>
            {/if}
          {/each}
        {:else}
          <div class="fields">
            {#each sortedFields as field, index}
              <Field {...field} bind:this={fieldElements[field.index]} />
            {/each}
          </div>
        {/if}
      </form>
    </article>

    <nav class="input-options" style="display: none;">
      <div class="input-options-section">
        <p>
          <select bind:value={show} on:change={onFilter}>
            <option value="all">{t("show_all_fields")}</option>
            <option value="important">{t("show_most_important_fields")}</option>
          </select>
        </p>
        <p>
          <select bind:value={sort} on:change={onSort}>
            <option value="alphabetical">{t("sort_alphabetically")}</option>
            <option value="importance">{t("sort_importance")}</option>
            <option value="index">{t("Sort by Index")}</option>
          </select>
        </p>
        <p>
          <label
            ><input type="checkbox" bind:checked={showCategories} />{t("show_categories")}</label
          >
        </p>
      </div>

      {#if EXTERNAL}
        <div class="input-options-section">
          {#each archetypes as a}
            <p>
              <button on:click|preventDefault={() => onArchetype(a)}
                >{t("Load Sample")} "{a.name}"</button
              >
            </p>
          {/each}
        </div>
      {/if}

      <div class="input-options-section">
        <p><button on:click|preventDefault={onResetValues}>{t("reset_to_average")}</button></p>
        <p><button on:click|preventDefault={onRandomize}>{t("randomize_values")}</button></p>
      </div>

      <button class="check-score" disabled={loading} on:click|preventDefault={onSubmit}
        >{t("run_model")}</button
      >

      {#if scorePosition == "left"}
        <div class="score">
          <div class="score-label">{t("risk_score")}</div>
          <div class="score-value">
            {#if loading}
              <div class="loader" />
            {:else}
              {score > 0 ? score : "?"}
            {/if}
          </div>
        </div>
      {/if}
    </nav>
  </section>

  <section>
    <!-- <header class="output"> -->
    <!--   <h2>{t("model_output")}</h2> -->
    <!--   <p> -->
    <!--     <select bind:value={explainView}> -->
    <!--       <option value="text">{t("view_results_as_text")}</option> -->
    <!--       <option value="poem">{t("View as poem")}</option> -->
    <!--       <option value="trees">{t("view_results_as_trees")}</option> -->
    <!--     </select> -->
    <!--   </p> -->
    <!-- </header> -->
    <article class="right">
      {#if score != 0}
				<div class="score" style="background-color: hsl({100 - score * 100}, 100%, 50%)">
					<div class="score-label">{t("risk_score")}</div>
					<div class="score-value">
						{#if loading}
							<div class="loader" />
						{:else}
							{score > 0 ? score : "?"}
						{/if}
					</div>
				</div>
        {#if explainView == "trees"}
          <div class="text-trees">
            {#key score}
              {#each Array(treeIndex + 1) as _, index (index)}
                <LazyLoad>
                  <div class="text-tree" in:fade={{ duration: 1000 }}>
                    <h3>{t("Tree")} {index + 1}</h3>
                    <Tree data={trees[index]} {index} userFields={$userFields} />
                  </div>
                </LazyLoad>
              {/each}
            {/key}
          </div>
        {:else if explainView == "poem"}
          <div class="text-poem">
						{#key score}
							<TextBlock />
						{/key}
            <span style="text-transform:uppercase; font-style: italic; line-height: 1.2;"
              >The Risk Score Is {score}.</span
            >
          </div>
        {:else}
          <div class="text-trees">
            {#key score}
              {#each Array(treeIndex + 1) as _, index (index)}
                <div class="text-tree">
                  <h3>{t("Tree")} {index + 1}</h3>
                  <TextTree data={trees[index]} />
                </div>
              {/each}
            {/key}
          </div>
        {/if}
      {:else}
        <!-- <div class="no-score"> -->
        <!--   <div> -->
        <!--     {#if loading} -->
        <!--       <p>...{t("loading")}...</p> -->
        <!--     {:else} -->
        <!--       <p>{t("Enter some data and run the model to see results.")}</p> -->
        <!--     {/if} -->
        <!--   </div> -->
        <!-- </div> -->
      {/if}
    </article>
  </section>
</main>

{#if showAbout}
  <div
    class="about"
    on:click={(e) => {
      if (e.target == e.currentTarget) toggleAbout();
    }}
  >
    <div class="about-inner">
      <div class="about-header">
        <h1>Rotterdam Risk Score Calculator</h1>
        <a href="#" on:click|preventDefault={toggleAbout}>Close</a>
      </div>

      <p>
        The risk score calculator lets you run a machine learning model that the city of Rotterdam
        uses to automate risk assessments for citizens seeking government services. The model is
        being run in real time, based on the values you enter.
      </p>

      <p>Higher scores indicate higher risks for fraud.</p>

      <p>
        By <a href="https://lav.io">Sam Lavigne</a> with assistance from
        <a href="https://amyqu.work/">Amy Qu</a>.
      </p>
      <p>
        This work is and based on reporting by Lighthouse Reports. Learn more about their <a
          href="https://www.lighthousereports.com/investigation/suspicion-machines/"
          >methodology here</a
        >.
      </p>

      <p>
        This project was funded with generous support from the <a
          href="https://www.eyebeam.org/eyebeam-center-for-the-future-of-journalism/"
          >Eyebeam Center for the Future of Journalism</a
        >, and the
        <a href="https://artisticinquiry.org/">Center for Artistic Inquiry and Reporting</a>.
      </p>
    </div>
  </div>
{/if}

<style>
	*::-webkit-scrollbar{
		display: none;
	}
  .text-poem {
    font-size: 1.0vh;
  }
  .about {
    position: fixed;
    z-index: 999;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(255, 255, 255, 0.8);
    display: grid;
    place-items: center;
    /* margin: 20px; */
    /* padding: 20px; */
  }

  .about-inner {
    background-color: #fff;
    border: 3px solid #000;
    padding: 30px;
    max-width: 700px;
    font-size: 1.1em;
    margin: 10px;
  }

  main {
    display: grid;
    grid-template-columns: 1fr 1fr;
    height: 100vh;
    /* height: -webkit-fill-available; */
  }

  .break {
    flex-basis: 100%;
    height: 0;
  }

  article.right {
    position: relative;
  }

  section {
    display: grid;
    height: 100vh;
    /* height: -webkit-fill-available; */
    grid-template-rows: auto 1fr auto;
    /* box-shadow: inset 0px 0px 20px 10px rgba(0,0,0,0.9); */
  }

  section:first-child {
    border-right: 5px solid #000;
  }

  header {
    border-bottom: 2px solid #000;
    /* box-shadow: 0px 5px 10px rgba(0, 0, 0, 0.2); */
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
  }

  header p {
    /* opacity: 0.7; */
  }

  h1 {
    font-size: 25px;
    font-weight: normal;
    margin: 0;
  }

  h2 {
    font-size: 20px;
    font-weight: normal;
    margin: 0;
  }

  nav {
    /* box-shadow: 0px -5px 10px rgba(0, 0, 0, 0.2); */
  }

  header,
  article,
  nav {
    padding: 15px;
  }

  header {
    padding: 7px 15px;
  }

  header,
  nav {
    background-color: #fffee0;
    background-color: #eee;
  }

  header.output,
  nav.output {
    background-color: #e0fdff;
    background-color: #eee;
  }

  article {
    overflow: scroll;
  }

  .input-options {
    display: flex;
    align-items: top;
  }

  .input-options p {
    margin: 0;
    margin-bottom: 10px;
  }

  .input-options p:last-child {
    margin: 0;
  }

  .input-options button,
  select {
    width: 100%;
    background-color: #fff;
    border: 1px solid #000;
    cursor: pointer;
  }

  .input-options button {
    /* border-right-width: 4px; */
    /* border-bottom-width: 4px; */
    /* border-right-color: #666; */
    box-shadow: 3px 3px 0px #000;
  }

  .input-options button:active {
    position: relative;
    top: 2px;
    left: 2px;
  }

  .input-options .check-score {
    width: auto;
    height: 100%;
    background-color: yellow;
    cursor: pointer;
    margin-left: auto;
    padding: 20px;
    font-size: 1.5em;
  }

  .input-options-section {
    margin-right: 10px;
  }

  .cat-name {
    font-weight: normal;
    text-transform: capitalize;
    font-size: 20px;
  }

  fieldset {
    margin-bottom: 20px;
  }

  .output {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .output .tip {
    width: 50%;
    margin: 0;
  }

  .left {
  }

  .fields {
    display: grid;
    grid-template-columns: 1fr 1fr;
    /* grid-gap: 15px; */
  }

  nav {
    /* background-color: #333; */
  }

  button {
    font-size: 1em;
  }

  .score {
    position: absolute;
    top: 50%;
    left: 50%;
		transform: translate(-50%, -50%);
    display: flex;
		flex-direction: column;
    border: 1px solid #000;
    align-items: center;
    justify-content: center;
		font-size: 2vw;
		box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.3);
    /* transition: all 3s; */
    /* background-color: hsl(100, 100%, 50%); */
  }

  .score-label,
  .score-value {
    padding: 20px;
    text-align: center;
  }

  .score-label {
    border-bottom: 1px solid #000;
    font-size: 0.9em;
    /* color: #fff; */
  }

  .score-value {
		font-size: 1.2em;
    /* color: #fff; */
  }

  h3 {
    font-weight: normal;
    border-bottom: 1px solid #000;
  }

  .no-score {
    display: grid;
    place-items: center;
    height: 100%;
    font-size: 2em;
    color: #888;
    background-color: #eee;
  }

  .edit-input {
    display: none;
  }

  @media (max-width: 900px) {
    main {
      grid-template-columns: 1fr;
      height: 100vh;
      height: -webkit-fill-available;
      min-height: -webkit-fill-available;
    }
    .fields {
      grid-template-columns: 1fr;
    }
    .edit-input {
      display: block;
    }
    .input-options button {
      padding: 5px;
    }
    .input-options select,
    .input-options button,
    .input-options {
      font-size: 14px;
      margin: 0;
    }
    .input-options .check-score {
      padding: 5px;
      font-size: 16px;
    }
    .input-options.edit-input {
      margin-top: 15px;
    }
    header,
    article,
    nav {
      padding: 5px;
    }
    header p,
    nav p {
      font-size: 0.8em;
      margin: 4px 0px;
    }
  }
  a {
    color: #000;
  }
</style>
