<script>
  import FIELDS from "./fields.js";
  import Field from "./Field.svelte";
  import { userFields } from "./stores.js";
  // import TextExplain from "./TextExplain.svelte";
  import TextTree from "./TextTree.svelte";
  import Tree from "./Tree.svelte";
  import TREES from "./trees.json";
  import { fade } from "svelte/transition";
  import LazyLoad from "@dimfeld/svelte-lazyload";
  import archetypes from "./archetypes.json";
  import { t } from "./i18n";

  // const worker = new Worker(new URL("./worker.js", import.meta.url), {
  //   type: "module",
  // });

  const params = new URLSearchParams(window.location.search);

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
  };

  let score = 0;
  let loading = false;
  let sort = "alphabetical";
  let show = "all";
  let explainView = "text";
  let treeIndex = 499;
  let fieldElements = [];
  let showCategories = true;
  let categories = [];
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
      sortedFields = FIELDS.filter((f) => f.feature_importance > 10);
      onSort();
    }
    setCategories();
  }

  function toggleText() {
    showText = !showText;
  }

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
</script>

<main>
  <section>
    <header>
      <h1>{t("data_input")}</h1>
      <p>{t("enter_your_data")}</p>
    </header>
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
              <Field {...field} bind:this={fieldElements[index]} />
            {/each}
          </div>
        {/if}
      </form>
    </article>

    <nav class="input-options">
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
          </select>
        </p>
        <p>
          <label
            ><input type="checkbox" bind:checked={showCategories} />{t("show_categories")}</label
          >
        </p>
      </div>

      <div class="input-options-section">
        {#each archetypes as a}
          <p>
            <button on:click|preventDefault={() => onArchetype(a)}>Load Sample "{a.name}"</button>
          </p>
        {/each}
      </div>

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
    <header class="output">
      <h1>{t("model_output")}</h1>
      <p>
        <select bind:value={explainView}>
          <option value="text">{t("view_results_as_text")}</option>
          <option value="trees">{t("view_results_as_trees")}</option>
        </select>
      </p>
    </header>
    <article>
      {#if score != 0 && loading === false}
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
        <div class="no-score">
          <div>
            {#if loading}
              <p>...{t("loading")}...</p>
            {:else}
              <p>{t("Enter some data and run the model to see results.")}</p>
            {/if}
          </div>
        </div>
      {/if}
    </article>
    <nav class="output">
      <p class="tip">
        {t("model_description")}
      </p>
      <div>
        {#if scorePosition != "left"}
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
        {/if}
        <div class="input-options edit-input">
          <button
            on:click={() => {
              window.scrollTo({ top: 0, left: 0, behavior: "smooth" });
            }}
          >
            {t("Edit Input")}
          </button>
        </div>
      </div>
    </nav>
  </section>
</main>

<style>
  main {
    display: grid;
    grid-template-columns: 1fr 1fr;
    height: 100vh;
  }

  section {
    display: grid;
    height: 100vh;
    grid-template-rows: auto 1fr auto;
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
  }

  header p {
    opacity: 0.7;
  }

  h1 {
    font-size: 30px;
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
    border-bottom: 2px solid #000;
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
    display: flex;
    border: 1px solid #000;
    /* transition: all 3s; */
    /* background-color: hsl(100, 100%, 50%); */
  }

  .score-label,
  .score-value {
    padding: 10px;
    text-align: center;
  }

  .score-label {
    border-right: 1px solid #000;
    font-size: 0.9em;
    /* color: #fff; */
  }

  .score-value {
    font-size: 30px;
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
  }
</style>
