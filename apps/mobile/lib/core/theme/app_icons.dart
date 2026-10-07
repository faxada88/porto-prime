import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppIcons {
  // Navegação e ações
  static const home = LucideIcons.home;
  static const search = LucideIcons.search;
  static const bag = LucideIcons.shoppingBag;
  static const cart = LucideIcons.shoppingCart;
  static const user = LucideIcons.user;
  static const bell = LucideIcons.bell;
  static const chevronDown = LucideIcons.chevronDown;
  static const chevronRight = LucideIcons.chevronRight;
  static const arrowRight = LucideIcons.arrowRight;
  static const arrowLeft = LucideIcons.arrowLeft;
  static const close = LucideIcons.x;
  static const plus = LucideIcons.plus;
  static const minus = LucideIcons.minus;
  static const check = LucideIcons.check;
  static const checkCircle = LucideIcons.circleCheck;
  static const more = LucideIcons.ellipsis;
  static const filter = LucideIcons.slidersHorizontal;
  static const refresh = LucideIcons.refreshCw;

  // Conta e segurança
  static const mail = LucideIcons.mail;
  static const phone = LucideIcons.phone;
  static const lock = LucideIcons.lock;
  static const shield = LucideIcons.shieldCheck;
  static const eye = LucideIcons.eye;
  static const eyeOff = LucideIcons.eyeOff;
  static const help = LucideIcons.helpCircle;
  static const settings = LucideIcons.settings;
  static const logout = LucideIcons.logOut;
  static const badge = LucideIcons.badge;
  static const calendar = LucideIcons.calendar;
  static const briefcase = LucideIcons.briefcase;
  static const building = LucideIcons.building2;

  // Operação
  static const mapPin = LucideIcons.mapPin;
  static const navigation = LucideIcons.navigation;
  static const route = LucideIcons.route;
  static const clock = LucideIcons.clock;
  static const bike = LucideIcons.bike;
  static const package = LucideIcons.package;
  static const packageOpen = LucideIcons.packageOpen;
  static const list = LucideIcons.listOrdered;
  static const history = LucideIcons.history;
  static const wallet = LucideIcons.wallet;
  static const money = LucideIcons.circleDollarSign;
  static const banknote = LucideIcons.banknote;
  static const creditCard = LucideIcons.creditCard;
  static const receipt = LucideIcons.receipt;
  static const power = LucideIcons.power;
  static const radar = LucideIcons.radar;
  static const sparkles = LucideIcons.sparkles;
  static const waves = LucideIcons.waves;
  static const tag = LucideIcons.badgePercent;
  static const alert = LucideIcons.circleAlert;
  static const info = LucideIcons.circleHelp;

  // Categorias
  static const beer = LucideIcons.beer;
  static const wine = LucideIcons.wine;
  static const spirits = LucideIcons.martini;
  static const softDrink = LucideIcons.cupSoda;
  static const energy = LucideIcons.zap;
  static const water = LucideIcons.droplet;
  static const ice = LucideIcons.snowflake;
  static const convenience = LucideIcons.shoppingBag;
  static const combo = LucideIcons.packageOpen;
  static const offers = LucideIcons.badgePercent;
  static const all = LucideIcons.layoutGrid;

  static IconData category(String name) {
    final value = name
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    if (value == 'todos' || value == 'todas') return all;
    if (value.contains('cervej')) return beer;
    if (value.contains('vinh')) return wine;
    if (value.contains('whisk') ||
        value.contains('destil') ||
        value.contains('vodk') ||
        value.contains('gin') ||
        value.contains('licor')) {
      return spirits;
    }
    if (value.contains('energ')) return energy;
    if (value.contains('refriger') ||
        value.contains('suco') ||
        value.contains('sem alcool')) {
      return softDrink;
    }
    if (value.contains('agua')) return water;
    if (value.contains('gelo')) return ice;
    if (value.contains('conveni') ||
        value.contains('snack') ||
        value.contains('petisco')) {
      return convenience;
    }
    if (value.contains('combo') ||
        value.contains('kit') ||
        value.contains('pack')) {
      return combo;
    }
    if (value.contains('oferta') ||
        value.contains('promo') ||
        value.contains('desconto')) {
      return offers;
    }
    return package;
  }
}
