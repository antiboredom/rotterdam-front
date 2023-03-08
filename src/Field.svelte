<script>
  import { userFields, highlightedField, lang } from "./stores.js";
  import { t } from "./i18n.js";

  export let show = true;

  export let feature_dutch_underscore,
    feature_dutch,
    feature_english_auto_translate,
    description,
    description_dutch,
    feature_importance,
    notes,
    understand,
    default_value,
    sum,
    category,
    type,
    feature_english,
    minval,
    maxval,
    index;

  console.log(description, description_dutch)
  let highlight=false;
  let el;

  let timeout;
  export function animate(){
    clearTimeout(timeout);
    opacity = 0;
    timeout = setTimeout(() => {
      opacity = 1;
    }, 300);
  }

  function checkVal(e) {
    if (e.target.value > maxval)  {
      $userFields[index] = maxval;
    }

    if (e.target.value < minval) {
      $userFields[index] = minval;
      return false;
    }
  }

  let opacity = 1;
  // userFields.subscribe(val => {
  //     console.log(index, val[index]);
  // });

  highlightedField.subscribe(val => {
    if (val == index) {
      highlight = true;
      if (el) {
        el.scrollIntoView({behavior: "smooth"});
      }
    } else {
      highlight = false;
    }
  });
</script>

<div class="field" id={"field-" + index} class:highlight={highlight} bind:this={el}>
  <div class="input-holder" style:opacity={opacity}>
    {#if type == "boolean"}
      <select name={feature_dutch_underscore} bind:value={$userFields[index]}>
        <option value={0.0}>{t("false")}</option>
        <option value={1.0}>{t("true")}</option>
      </select>
    {:else}
      <input
        name={feature_dutch_underscore}
        type="number"
        step={type == "float" ? 0.01 : 1}
        min={minval}
        max={maxval}
        bind:value={$userFields[index]}
        on:change={checkVal}
      />
    {/if}
    {#if type != "boolean"}
      <div class="minmax">{minval.toFixed(3)} {t("to")} {maxval.toFixed(3)}</div>
    {/if}
  </div>
  <label for={feature_dutch_underscore}>
    <div class="title">{$lang == "en" ? feature_english_auto_translate : feature_dutch}</div>
    <div class="description">
      {$lang == "en" ? description : description_dutch}
    </div>
    <div class="importance">{t("importance")}: {feature_importance}%</div>
  </label>
</div>

<style>
  .field {
    /* margin: 30px 0px; */
    display: flex;
    /* max-width: 400px; */
    align-items: flex-start;
    padding: 15px;
    border-bottom: 1px solid #666;
    transition: 0.5s all;
  }

  .field.highlight {
    background-color: yellow;
  }

  .minmax {
    text-align: center;
    margin-top: 5px;
    font-size: 0.8em;
    color: #777;
  }

  /* .field:nth-child(even) { */
  /*   border-left: 1px solid #666; */
  /*   border-top: 1px solid #666; */
  /* } */
  /*  */
  /* .field:nth-child(odd) { */
  /*   border-top: 1px solid #666; */
  /* } */

  /* .field input, .field label { */
  /*   display: inline; */
  /* } */

  .field div {
  }

  .title {
    font-size: 1em;
    text-transform: capitalize;
  }

  .importance {
    font-size: 0.8em;
    color: #777;
  }

  .description {
    font-size: 0.85em;
  }

  input,
  select {
    font-size: 1em;
    font-family: Times, sans-serif;
    border: 1px solid #000;
    /* width: 5em; */
    /* width: 100%; */
    /* display: block; */
    width: 90px;
    padding: 10px;
    text-align: center;
    background-color: #fff;
  }
  select {
  }
  .input-holder {
    margin-right: 20px;
    width: 90px;
    opacity: 1;
    transition: 0.3s opacity;
  }
  input[type="number"]::-webkit-inner-spin-button,
  input[type="number"]::-webkit-outer-spin-button {
    opacity: 1;
  }
  /* .field { */
  /*   margin: 0; */
  /* } */
</style>
