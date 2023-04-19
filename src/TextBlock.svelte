<script>
  import TREES from "./trees.json";
  import FIELDS from "./fields.js";
  import { userFields, lang } from "./stores.js";
  import { t } from "./i18n.js";

  const featureKey = {};
  for (const f of FIELDS) {
    featureKey[f.index] = f;
  }

  const keys = TREES.keys;
  const trees = TREES.trees;

  let explanations = {};
  let tests = [];

  for (let tree of trees) {
    let index = 0;
    let score = null;
    while (score === null) {
      const [t_id, var_id, split, left, right] = tree[index];
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
      if (!explanations[var_id]) explanations[var_id] = [];
      const test = `${var_id}:${inp}:${comparison}`;
      if (!tests.includes(test)) {
        explanations[var_id].push({ inp, split, comparison });
        tests.push(test);
      }

      if (inp < split) {
        index = left;
      } else {
        index = right;
      }
    }
  }
</script>

<span>
  {#each Object.keys(explanations) as var_id, var_index}
    {t("Because")}
    {$lang == "en" ? featureKey[var_id].feature_english_auto_translate : featureKey[var_id].feature_dutch}
    {#each explanations[var_id] as part, index}
      {#if featureKey[var_id].type == "boolean"}is {part.comparison}{:else}{t('is')} {part.comparison} {t('than')} {part.split}{/if}{#if var_index <= Object.keys(explanations).length-2 && index <= explanations[var_id].length-1}{index == explanations[var_id].length - 1 ? `, ${t('and')} ` : ` ${t('and')} `}{/if}
    {/each}
  {/each}
</span>

<style>
  span {
    text-transform:uppercase;
    font-style: italic;
    line-height: 1.2;
  }
</style>
