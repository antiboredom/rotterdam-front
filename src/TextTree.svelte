<script>
  import TREES from "./trees.json";
  import FIELDS from "./fields.js";
  import { userFields, highlightedField, lang } from "./stores.js";
  import { t } from "./i18n.js";

  // export let userFields = [];
  export let data;

  const featureKey = {};

  for (const f of FIELDS) {
    featureKey[f.index] = f;
  }

  const keys = TREES.keys;
  const trees = TREES.trees;

  let score = null;
  let index = 0;
  let explanations = [];

  while (score === null) {
    const [t_id, var_id, split, left, right] = data[index];
    if (var_id == -1) {
      score = split;
      break;
    }
    const inp = $userFields[var_id];
    const type = featureKey[var_id].type;
    let comparison;
    if (type == "boolean") {
      comparison = inp < split ? t("false") : t("true");
    } else {
      comparison = inp < split ? t("less") : t("more");
    }
    // const comparison = inp < split ? "less" : "more";
    const name = $lang == "en" ? featureKey[var_id].feature_english_auto_translate : featureKey[var_id].feature_dutch;
    explanations.push({ var_id, name, type, inp, split, comparison });

    if (inp < split) {
      index = left;
    } else {
      index = right;
    }
  }

  // let clauses = explanations.map(e => {
  //   if (e.type == "boolean") return `${e.name.toLowerCase()} is ${e.comparison}`;
  //   else return `${e.name.toLowerCase()} is ${e.comparison} than ${e.split}`;
  // }).join(", and ");
  //
  // let sentence = `Because ${clauses}, the score is ${score}.`;
</script>

<p>
  {t("Because")}
  {#each explanations as e, index}
    <span class="name" on:click={() => highlightedField.set(e.var_id)}>{e.name.toLowerCase()}</span> {t("is")}
    {#if e.type == "boolean"}
      <span class="comp">{e.comparison}</span>{#if index < explanations.length - 1}, {t("and")} {" "}{:else},{/if}
    {:else}
      <span class="comp">{e.comparison} {t("than")} {e.split}</span>{#if index < explanations.length - 1}, {t("and")} {" "}{:else},{/if}
    {/if}
  {/each}
  {t("the score is")} <span class="score">{score}</span>.
</p>

<!--  -->
<!-- 
{#each explanations as e}
  <p>
    Because <span class="name">{e.name.toLowerCase()}</span> is
    {#if e.type == "boolean"}
      <span class="comp">{e.comparison}</span>.
    {:else}
      <span class="comp">{e.comparison} than {e.split}</span>.
    {/if}
  </p>
{/each}
<p>Score is <span class="score">{score}</span>.</p>
 -->
<style>
  p {
    line-height: 1.5;
  }
  .name {
    /* text-decoration: underline; */
    /* border-bottom: 1px solid yellow; */
    border-bottom: 1px solid orange;
    cursor: pointer;
  }
  .name:hover {
    background-color: yellow;
  }
  .comp {
    /* border-bottom: 1px solid red; */
    /* background-color: lightblue; */
    /* background-color: orange; */
    /* background-color: yellow; */
  }
  .score {
    /* border-bottom: 1px solid orange; */
    /* background-color: yellow; */
    /* background-color: orange; */
  }
</style>
