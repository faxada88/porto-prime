import { Apple, Baby, BadgePercent, Beef, Beer, CakeSlice, Carrot, Coffee, Croissant, CupSoda, Droplet, Dumbbell, Fish, Flower2, LayoutGrid, Leaf, Martini, Milk, PackageOpen, PawPrint, Pill, Pizza, Sandwich, ShoppingCart, Snowflake, SprayCan, Wine, Zap } from 'lucide-react';
export const CATEGORY_ICONS = [
  {key:"barbecue",label:"Churrasco e carnes",Icon:Beef,terms:["churrasc", "carne", "acougue", "espet", "bovino", "frango"],background:'#FFF0E4',foreground:'#98572A'},
  {key:"fitness",label:"Fitness e suplementos",Icon:Dumbbell,terms:["fitness", "fit", "suplement", "protein", "academia", "ginast"],background:'#EDE9FF',foreground:'#6655A2'},
  {key:"fruit",label:"Frutas",Icon:Apple,terms:["fruta", "hortifruti", "acai"],background:'#E6F4EA',foreground:'#36734A'},
  {key:"vegetables",label:"Verduras e legumes",Icon:Carrot,terms:["verdur", "legum", "hortalic", "salad"],background:'#EAF5E2',foreground:'#487334'},
  {key:"fish",label:"Peixes e frutos do mar",Icon:Fish,terms:["peixe", "pescad", "camarao", "marisco", "frutos do mar"],background:'#E3F2F8',foreground:'#2E708D'},
  {key:"bakery",label:"Padaria e pães",Icon:Croissant,terms:["padaria", "pao", "paes", "panific", "salgad"],background:'#FFF1D8',foreground:'#8D5E10'},
  {key:"coffee",label:"Café e chá",Icon:Coffee,terms:["cafe", "caffe", "cha"],background:'#F4E9DF',foreground:'#80543D'},
  {key:"dairy",label:"Leite e laticínios",Icon:Milk,terms:["leite", "laticin", "queijo", "iogurte"],background:'#E5F3FB',foreground:'#356D8D'},
  {key:"sweets",label:"Doces e sobremesas",Icon:CakeSlice,terms:["doce", "sobremesa", "bolo", "chocolate", "sorvet"],background:'#F8E4EA',foreground:'#8C4059'},
  {key:"pizza",label:"Pizzas",Icon:Pizza,terms:["pizza"],background:'#FFF0E4',foreground:'#98572A'},
  {key:"snacks",label:"Lanches e sanduíches",Icon:Sandwich,terms:["lanche", "hamburg", "sanduich", "burger"],background:'#FFF1D8',foreground:'#8D5E10'},
  {key:"vegan",label:"Natural e vegano",Icon:Leaf,terms:["vegan", "vegetarian", "natural", "organico"],background:'#E6F4EA',foreground:'#36734A'},
  {key:"pharmacy",label:"Farmácia e saúde",Icon:Pill,terms:["farmac", "saude", "medic", "higiene"],background:'#E3F2F8',foreground:'#2E708D'},
  {key:"pets",label:"Pets",Icon:PawPrint,terms:["pets", "petshop", "racao", "animal", "cachorro", "gato"],background:'#FFF0E4',foreground:'#98572A'},
  {key:"cleaning",label:"Limpeza",Icon:SprayCan,terms:["limpeza", "deterg", "lavander"],background:'#E5F3FB',foreground:'#356D8D'},
  {key:"beauty",label:"Beleza e cuidados",Icon:Flower2,terms:["beleza", "cosmet", "perfum", "cuidado"],background:'#F8E4EA',foreground:'#8C4059'},
  {key:"baby",label:"Bebês e infantil",Icon:Baby,terms:["bebe", "infant", "fralda"],background:'#EDE9FF',foreground:'#6655A2'},
  {key:"beer",label:"Cervejas",Icon:Beer,terms:["cervej"],background:'#FFF1C9',foreground:'#8D5E10'},
  {key:"wine",label:"Vinhos",Icon:Wine,terms:["vinh"],background:'#F8E4EA',foreground:'#8C4059'},
  {key:"spirits",label:"Destilados",Icon:Martini,terms:["destil", "deslit", "whisk", "vodk", "gin", "licor", "cachac"],background:'#FFE9DA',foreground:'#98572A'},
  {key:"softDrink",label:"Refrigerantes e sucos",Icon:CupSoda,terms:["refriger", "suco", "sem alcool"],background:'#FFE9E2',foreground:'#AA4E3E'},
  {key:"energy",label:"Energéticos",Icon:Zap,terms:["energ"],background:'#ECE7FF',foreground:'#6655A2'},
  {key:"water",label:"Águas",Icon:Droplet,terms:["agua"],background:'#E3F2F8',foreground:'#2E708D'},
  {key:"ice",label:"Gelo",Icon:Snowflake,terms:["gelo"],background:'#E7F4FA',foreground:'#317898'},
  {key:"convenience",label:"Conveniência e mercearia",Icon:ShoppingCart,terms:["conveni", "snack", "petisco", "mercearia", "biscoit"],background:'#E6F4EA',foreground:'#36734A'},
  {key:"combo",label:"Combos e kits",Icon:PackageOpen,terms:["combo", "kit", "pack"],background:'#FFEED4',foreground:'#95611C'},
  {key:"offers",label:"Ofertas",Icon:BadgePercent,terms:["oferta", "promo", "desconto"],background:'#FFE7E1',foreground:'#B64E3E'},
  {key:"general",label:"Categoria personalizada",Icon:LayoutGrid,terms:[],background:'#EAF5F1',foreground:'#0C655B'},
] as const;
export function suggestedCategoryIcon(name: string) {
 const value=name.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 const words=value.split(/[^a-z0-9]+/);
 return CATEGORY_ICONS.find(item=>item.terms.some(term=>term.includes(' ')?value.includes(term):words.some(word=>term.length<=3?word===term:word.startsWith(term))))?.key || '';
}
export function categoryIcon(key: string | undefined, name = '') {return CATEGORY_ICONS.find(item=>item.key===(key||suggestedCategoryIcon(name))) || CATEGORY_ICONS[CATEGORY_ICONS.length-1];}
