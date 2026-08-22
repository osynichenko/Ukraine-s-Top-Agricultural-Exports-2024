setwd("~/projects/UKRAINE")



install.packages("readxl")



library(readxl)



# Завантаження данних до датафреймів# 

ue_sno_1512 <- read_excel(path="ukraine_export_2024_sunflower_oil_1512.xlsx", sheet="Sheet1", col_names= TRUE)

ue_nh_040900 <- read_excel(path="ukraine_export_2024_natural_honey_040900.xlsx", sheet="Sheet1", col_names= TRUE)

ue_wln_ins_080231 <- read_excel(path="ukraine_export_2024_walnuts_in_shell_080231.xlsx", sheet="Sheet1", col_names= TRUE)
                              
ue_wln_sd_080232 <- read_excel(path="ukraine_export_2024_walnuts_shelled_080232.xlsx", sheet="Sheet1", col_names= TRUE)
                            
wwe_sno_1512 <- read_excel(path="whole_world_export_2024_sunflower_oil_1512.xlsx", sheet="Sheet1", col_names= TRUE)

wwe_nh_040900 <- read_excel(path="whole_world_export_2024_natural_honey_040900.xlsx", sheet="Sheet1", col_names= TRUE)

wwe_wln_ins_080231 <- read_excel(path="whole_world_export_2024_walnuts_in_shell_080231.xlsx", sheet="Sheet1", col_names= TRUE)

wwe_wln_sd_080232 <- read_excel(path="whole_world_export_2024_walnuts_shelled_080232.xlsx", sheet="Sheet1", col_names= TRUE)

wwe_sno_from_rf_1512 <- read_excel(path="whole_world_import_2024_from_rf_sunflower_oil_1512.xlsx", sheet="Sheet1", col_names= TRUE)



# Перевірка типа кожної колонки # 

class(ue_sno_1512$primaryValue)

class(ue_nh_040900$primaryValue)

class(ue_wln_ins_080231$primaryValue)

class(ue_wln_sd_08032$primaryValue)

class(wwe_sno_1512$primaryValue)

class(wwe_nh_040900$primaryValue)

class(wwe_wln_ins_080231$primaryValue)

class(wwe_wln_sd_080232$primaryValue)

class(wwe_sno_from_rf_1512$primaryValue)



# Створення кастомної функції розрахунку світової частки "world_share" #

world_share <- function(df, iso = "UKR") {
  df$primaryValue <- as.numeric(df$primaryValue)           # захист незалежно від типу
  stopifnot(sum(duplicated(df$reporterISO)) == 0)          # перевірка на дублі репортерів
  world_total <- sum(df$primaryValue, na.rm = TRUE)
  ukr_value   <- sum(df$primaryValue[df$reporterISO == iso], na.rm = TRUE)
  ord  <- df[order(-df$primaryValue), ]
  rank <- which(ord$reporterISO == iso)
  list(world_total = world_total, value = ukr_value,
       share_pct = round(ukr_value / world_total * 100, 2), rank = rank)
}



# Послідовний виклик функції розрахунку світової частки "world_share" для кожного товару #

world_share(wwe_sno_1512)       # соняшникова олія
world_share(wwe_nh_040900)      # мед
world_share(wwe_wln_sd_080232)  # горіхи лущені
world_share(wwe_wln_ins_080231) # горіхи в шкаралупі



# Зручний перегляд структури списку #

View(world_share(wwe_sno_1512))

View(world_share(wwe_nh_040900))

View(world_share(wwe_wln_sd_080232))

View(world_share(wwe_wln_ins_080231))



# розрахунку світової частки "world_share" для усіх горіхів#

combined_wlnts <- rbind(wwe_wln_sd_080232[, c("reporterISO","primaryValue")],
                  wwe_wln_ins_080231[, c("reporterISO","primaryValue")])
combined_wlnts$primaryValue <- as.numeric(combined_wlnts$primaryValue)
combined_wlnts_sum <- aggregate(primaryValue ~ reporterISO, data = combined_wlnts, sum)
world_share(combined_wlnts_sum)



View(world_share(combined_wlnts_sum))



# Mirror-дані по рф #

wwe_sno_from_rf_1512$primaryValue <- as.numeric(wwe_sno_from_rf_1512$primaryValue)
unique(wwe_sno_from_rf_1512$partnerISO)   # має бути "RUS"
unique(wwe_sno_from_rf_1512$flowCode)     # має бути "M"
sum(wwe_sno_from_rf_1512$primaryValue, na.rm = TRUE)



ukr_from_world  <- wwe_sno_1512$primaryValue[wwe_sno_1512$reporterISO == "UKR"]
ukr_from_own    <- as.numeric(ue_sno_1512$primaryValue)
stopifnot(abs(ukr_from_world - ukr_from_own) < 1)



# Перевірки #

ukr_from_world
ukr_from_own
length(ukr_from_world)
length(ukr_from_own)
ukr_from_world - ukr_from_own



# Створення кастомної функції build_row() #

build_row <- function(result, product) {
  data.frame(
    product           = product,
    world_total_usd   = result$world_total,
    ukraine_value_usd = result$value,
    ukraine_share_pct = result$share_pct,
    ukraine_rank      = result$rank
  )
}



# Виклик build_row() для кожного товару та обʼєднання за допомогою rbind() для створення фінальної таблиці експорту #

summary_table <- rbind(
  build_row(world_share(wwe_sno_1512),       "Sunflower/safflower/cottonseed oil (HS 1512)"),
  build_row(world_share(wwe_nh_040900),      "Natural honey (HS 0409)"),
  build_row(world_share(wwe_wln_sd_080232),  "Walnuts, shelled (HS 080232)"),
  build_row(world_share(wwe_wln_ins_080231), "Walnuts, in shell (HS 080231)"),
  build_row(world_share(combined_wlnts_sum), "Walnuts, combined (080231+080232)")
)


View(summary_table)


write.csv(summary_table, "summary_table.csv", row.names = FALSE, fileEncoding = "UTF-8")



# Дістаємо число рф як одне значення


rf_value <- sum(wwe_sno_from_rf_1512$primaryValue, na.rm = TRUE)

rf_value


# "Додаємо" рф як ще одного репортера у світовий набір даних #

rf_row <- data.frame(reporterISO = "RUS", primaryValue = rf_value)

wwe_sno_1512_with_rf <- rbind(
  wwe_sno_1512[, c("reporterISO", "primaryValue")],
  rf_row
)


wwe_sno_1512_with_rf



# Рахуємо частки за допоиогою world_share() вже на новому датафреймі #



ukraine_incl_rf <- world_share(wwe_sno_1512_with_rf)
ukraine_incl_rf

russia_incl_rf <- world_share(wwe_sno_1512_with_rf, iso = "RUS")
russia_incl_rf



build_row_country <- function(result, country) {
  data.frame(
    country   = country,
    value_usd = result$value,
    share_pct = result$share_pct,
    rank      = result$rank,
    world_total_usd = result$world_total
  )
}


sunflower_rf_scenario <- rbind(
  build_row_country(ukraine_incl_rf, "Ukraine"),
  build_row_country(russia_incl_rf, "Russia (mirror-data estimate)")
)

sunflower_rf_scenario

View(sunflower_rf_scenario)
