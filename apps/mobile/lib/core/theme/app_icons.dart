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
  static const trash = LucideIcons.trash2;
  static const truck = LucideIcons.truck;
  static const gift = LucideIcons.gift;
  static const layers = LucideIcons.layers;
  static const circle = LucideIcons.circle;
  static const menu = LucideIcons.menu;
  static const externalLink = LucideIcons.externalLink;

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
  static const store = LucideIcons.store;
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

  // Aliases de migração: mantêm a semântica dos componentes existentes
  // enquanto toda a aplicação passa a renderizar o mesmo conjunto Lucide.
  static const support_agent_rounded = help;
  static const shield_rounded = shield;
  static const person_rounded = user;
  static const person_outline_rounded = user;
  static const login_rounded = user;
  static const person_add_alt_1_rounded = plus;
  static const wb_sunny_rounded = sparkles;
  static const lock_rounded = lock;
  static const lock_outline_rounded = lock;
  static const arrow_forward_rounded = arrowRight;
  static const arrow_forward_ios_rounded = chevronRight;
  static const manage_search_rounded = search;
  static const chevron_right_rounded = chevronRight;
  static const shopping_bag_rounded = bag;
  static const shopping_bag_outlined = bag;
  static const two_wheeler_rounded = bike;
  static const two_wheeler_outlined = bike;
  static const storefront_rounded = store;
  static const storefront_outlined = store;
  static const fact_check_rounded = list;
  static const fact_check_outlined = list;
  static const edit_note_rounded = list;
  static const badge_rounded = badge;
  static const badge_outlined = badge;
  static const error_outline_rounded = alert;
  static const privacy_tip_rounded = shield;
  static const verified_rounded = checkCircle;
  static const search_rounded = search;
  static const refresh_rounded = refresh;
  static const notification_important_rounded = bell;
  static const notifications_active_rounded = bell;
  static const mark_chat_read_rounded = mail;
  static const reply_rounded = arrowLeft;
  static const cancel_rounded = close;
  static const pause_circle_rounded = clock;
  static const task_alt_rounded = checkCircle;
  static const hourglass_top_rounded = clock;
  static const lock_person_rounded = lock;
  static const alternate_email_rounded = mail;
  static const key_rounded = lock;
  static const help_outline_rounded = help;
  static const visibility_rounded = eye;
  static const visibility_outlined = eye;
  static const visibility_off_rounded = eyeOff;
  static const visibility_off_outlined = eyeOff;
  static const close_rounded = close;
  static const receipt_long_rounded = receipt;
  static const receipt_long_outlined = receipt;
  static const location_on_rounded = mapPin;
  static const location_city_outlined = building;
  static const bolt_rounded = energy;
  static const logout_rounded = logout;
  static const verified_user_rounded = shield;
  static const lock_reset_rounded = lock;
  static const location_off_rounded = mapPin;
  static const home_rounded = home;
  static const home_filled = home;
  static const add_location_alt_rounded = mapPin;
  static const route_rounded = route;
  static const numbers_rounded = badge;
  static const map_rounded = mapPin;
  static const local_post_office_rounded = mail;
  static const cake_outlined = calendar;
  static const phone_outlined = phone;
  static const business_outlined = building;
  static const category_outlined = all;
  static const route_outlined = route;
  static const numbers_outlined = badge;
  static const map_outlined = mapPin;
  static const home_work_outlined = building;
  static const mail_outline_rounded = mail;
  static const account_balance_wallet_outlined = wallet;
  static const work_outline_rounded = briefcase;
  static const credit_card_outlined = creditCard;
  static const credit_card_rounded = creditCard;
  static const local_post_office_outlined = mail;
  static const event_available_outlined = calendar;
  static const commute_rounded = bike;
  static const calendar_today_outlined = calendar;
  static const pin_outlined = mapPin;
  static const arrow_back_rounded = arrowLeft;
  static const check_rounded = check;
  static const edit_rounded = list;
  static const check_circle_rounded = checkCircle;
  static const unfold_more_rounded = chevronDown;
  static const shield_outlined = shield;
  static const priority_high_rounded = alert;
  static const pin_rounded = lock;
  static const payments_rounded = money;
  static const power_settings_new_rounded = power;
  static const radar_rounded = radar;
  static const grid_view_rounded = all;
  static const schedule_rounded = clock;
  static const timeline_rounded = route;
  static const inventory_2_rounded = package;
  static const account_balance_wallet_rounded = wallet;
  static const trending_up_rounded = money;
  static const calendar_view_week_rounded = calendar;
  static const delivery_dining_rounded = bike;
  static const history_rounded = history;
  static const settings_rounded = settings;
  static const dashboard_customize_rounded = all;
  static const add_card_rounded = creditCard;
  static const account_balance_rounded = banknote;
  static const south_west_rounded = arrowLeft;
  static const north_east_rounded = arrowRight;
  static const info_outline_rounded = info;
  static const delete_sweep_outlined = trash;

  static CategoryIconSpec categoryVisual(String name) {
    final value = _normalizeCategory(name);

    if (value == 'todos' || value == 'todas') {
      return const CategoryIconSpec(
        icon: all,
        size: 25,
        background: Color(0xFFEAF5F1),
        foreground: Color(0xFF0C655B),
      );
    }
    if (value.contains('cervej')) {
      return const CategoryIconSpec(
        icon: beer,
        offset: Offset(.5, .3),
        size: 27,
        background: Color(0xFFFFF1C9),
        foreground: Color(0xFF8D5E10),
      );
    }
    if (value.contains('vinh')) {
      return const CategoryIconSpec(
        icon: wine,
        offset: Offset(0, -.7),
        size: 27,
        background: Color(0xFFF8E4EA),
        foreground: Color(0xFF8C4059),
      );
    }
    if (value.contains('destil') ||
        value.contains('whisk') ||
        value.contains('vodk') ||
        value.contains('gin') ||
        value.contains('licor') ||
        value.contains('cachac')) {
      return const CategoryIconSpec(
        icon: spirits,
        offset: Offset(0, -.3),
        size: 26,
        background: Color(0xFFFFE9DA),
        foreground: Color(0xFF98572A),
      );
    }
    if (value.contains('refriger') ||
        value.contains('suco') ||
        value.contains('sem alcool')) {
      return const CategoryIconSpec(
        icon: softDrink,
        size: 26,
        background: Color(0xFFFFE9E2),
        foreground: Color(0xFFAA4E3E),
      );
    }
    if (value.contains('energ')) {
      return const CategoryIconSpec(
        icon: energy,
        offset: Offset(.4, 0),
        size: 25,
        background: Color(0xFFECE7FF),
        foreground: Color(0xFF6655A2),
      );
    }
    if (value.contains('agua')) {
      return const CategoryIconSpec(
        icon: water,
        offset: Offset(0, -.2),
        size: 25,
        background: Color(0xFFE3F2F8),
        foreground: Color(0xFF2E708D),
      );
    }
    if (value.contains('gelo')) {
      return const CategoryIconSpec(
        icon: ice,
        offset: Offset(0, -.5),
        size: 26,
        background: Color(0xFFE7F4FA),
        foreground: Color(0xFF317898),
      );
    }
    if (value.contains('conveni') ||
        value.contains('snack') ||
        value.contains('petisco') ||
        value.contains('mercearia')) {
      return const CategoryIconSpec(
        icon: convenience,
        size: 25,
        background: Color(0xFFE6F4EA),
        foreground: Color(0xFF36734A),
      );
    }
    if (value.contains('combo') ||
        value.contains('kit') ||
        value.contains('pack')) {
      return const CategoryIconSpec(
        icon: combo,
        size: 26,
        background: Color(0xFFFFEED4),
        foreground: Color(0xFF95611C),
      );
    }
    if (value.contains('oferta') ||
        value.contains('promo') ||
        value.contains('desconto')) {
      return const CategoryIconSpec(
        icon: offers,
        size: 25,
        background: Color(0xFFFFE7E1),
        foreground: Color(0xFFB64E3E),
      );
    }

    return const CategoryIconSpec(
      icon: package,
      size: 25,
      background: Color(0xFFEAF5F1),
      foreground: Color(0xFF0C655B),
    );
  }

  static IconData category(String name) => categoryVisual(name).icon;

  static String _normalizeCategory(String name) => name
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
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
}

class CategoryIconSpec {
  const CategoryIconSpec({
    required this.icon,
    required this.size,
    required this.background,
    required this.foreground,
    this.offset = Offset.zero,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;
  final Offset offset;
}
