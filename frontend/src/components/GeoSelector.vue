<template>
  <div class="geo-selector">
    <div class="field">
      <label class="label">{{ $t('geo.title') }}</label>
      <div class="geo-controls">
        <!-- Région -->
        <div class="field">
          <label class="label">{{ $t('geo.region') }}</label>
          <div class="control">
            <div class="select is-fullwidth">
              <select v-model="selectedRegion" @change="onRegionChange">
                <option value="">{{ $t('geo.allRegions') }}</option>
                <option v-for="region in regions" :key="region.region_nom" :value="region.region_nom">
                  {{ region.region_nom }}
                </option>
              </select>
            </div>
          </div>
        </div>

        <!-- Département -->
        <div class="field">
          <label class="label">{{ $t('geo.department') }}</label>
          <div class="control">
            <div class="select is-fullwidth">
              <select v-model="selectedDepartement" @change="onDepartementChange">
                <option value="">{{ $t('geo.allDepartments') }}</option>
                <option v-for="dept in filteredDepartements" :key="dept.departement_numero" :value="dept.departement_numero">
                  {{ dept.departement_nom }} ({{ dept.departement_numero }})
                </option>
              </select>
            </div>
          </div>
        </div>

        <!-- Commune -->
        <div class="field">
          <label class="label">{{ $t('geo.commune') }}</label>
          <div class="control">
            <input 
              v-model="communeSearch" 
              @input="searchCommunes"
              class="input" 
              type="text" 
              :placeholder="$t('geo.searchCommune')"
            />
          </div>
          <div v-if="communes.length > 0" class="commune-list">
            <div 
              v-for="commune in communes" 
              :key="commune.code_insee"
              @click="selectCommune(commune)"
              class="commune-item"
            >
              {{ commune.nom_commune }} ({{ commune.departement_numero }})
              <span class="population">{{ formatNumber(commune.population_commune) }} hab.</span>
            </div>
          </div>
        </div>

        <!-- CSP -->
        <div class="field">
          <label class="label">{{ $t('geo.csp') }}</label>
          <div class="control">
            <div class="select is-fullwidth">
              <select v-model="selectedCSP">
                <option value="">{{ $t('geo.allCSP') }}</option>
                <option v-for="csp in csps" :key="csp.csp" :value="csp.csp">
                  {{ csp.csp }} ({{ csp.count }})
                </option>
              </select>
            </div>
          </div>
        </div>

        <!-- Population -->
        <div class="field">
          <label class="label">{{ $t('geo.population') }}</label>
          <div class="field has-addons">
            <div class="control">
              <input 
                v-model.number="populationMin" 
                class="input" 
                type="number" 
                :placeholder="$t('geo.populationMin')"
              />
            </div>
            <div class="control">
              <span class="button is-static">-</span>
            </div>
            <div class="control">
              <input 
                v-model.number="populationMax" 
                class="input" 
                type="number" 
                :placeholder="$t('geo.populationMax')"
              />
            </div>
          </div>
        </div>

        <!-- Boutons d'action -->
        <div class="field is-grouped">
          <div class="control">
            <button @click="testQuery" class="button is-primary" :class="{ 'is-loading': isLoading }">
              <b-icon icon="magnify" size="is-small"></b-icon>
              <span>{{ $t('geo.testQuery') }}</span>
            </button>
          </div>
          <div class="control">
            <button @click="clearFilters" class="button">
              <b-icon icon="close" size="is-small"></b-icon>
              <span>{{ $t('geo.clear') }}</span>
            </button>
          </div>
        </div>

        <!-- Résultats -->
        <div v-if="queryResult !== null" class="notification" :class="queryResult.count > 0 ? 'is-success' : 'is-warning'">
          <strong>{{ $t('geo.result') }}:</strong> 
          {{ queryResult.count }} {{ $t('subscribers.subscribers') }}
          <div v-if="queryResult.count > 0" class="mt-2">
            <button @click="applyToQuery" class="button is-small is-success">
              {{ $t('geo.applyToQuery') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'GeoSelector',
  
  props: {
    value: {
      type: String,
      default: ''
    }
  },

  data() {
    return {
      regions: [],
      departements: [],
      communes: [],
      csps: [],
      
      selectedRegion: '',
      selectedDepartement: '',
      selectedCommune: '',
      selectedCSP: '',
      
      communeSearch: '',
      populationMin: null,
      populationMax: null,
      
      queryResult: null,
      isLoading: false,
      
      searchTimeout: null
    }
  },

  computed: {
    filteredDepartements() {
      if (!this.selectedRegion) return this.departements
      return this.departements.filter(d => d.region_nom === this.selectedRegion)
    }
  },

  mounted() {
    this.loadGeoData()
  },

  methods: {
    async loadGeoData() {
      try {
        // Charger les régions
        const regionsResponse = await this.$http.get('/api/geo/regions')
        this.regions = regionsResponse.data.data || []

        // Charger les départements
        const departementsResponse = await this.$http.get('/api/geo/departements')
        this.departements = departementsResponse.data.data || []

        // Charger les CSP
        const cspsResponse = await this.$http.get('/api/geo/csps')
        this.csps = cspsResponse.data.data || []
      } catch (e) {
        this.$utils.toast(this.$t('globals.messages.errorFetching'), 'is-danger')
        console.error('Erreur chargement données géographiques:', e)
      }
    },

    onRegionChange() {
      this.selectedDepartement = ''
      this.clearCommunes()
    },

    onDepartementChange() {
      this.clearCommunes()
    },

    searchCommunes() {
      if (this.searchTimeout) {
        clearTimeout(this.searchTimeout)
      }

      this.searchTimeout = setTimeout(async () => {
        if (this.communeSearch.length < 2) {
          this.communes = []
          return
        }

        try {
          const params = {
            search: this.communeSearch,
            limit: 10
          }
          
          if (this.selectedDepartement) {
            params.departement = this.selectedDepartement
          }

          const response = await this.$http.get('/api/geo/communes', { params })
          this.communes = response.data.data || []
        } catch (e) {
          console.error('Erreur recherche communes:', e)
        }
      }, 300)
    },

    selectCommune(commune) {
      this.selectedCommune = commune.nom_commune
      this.communeSearch = commune.nom_commune
      this.communes = []
    },

    clearCommunes() {
      this.selectedCommune = ''
      this.communeSearch = ''
      this.communes = []
    },

    clearFilters() {
      this.selectedRegion = ''
      this.selectedDepartement = ''
      this.selectedCommune = ''
      this.selectedCSP = ''
      this.communeSearch = ''
      this.populationMin = null
      this.populationMax = null
      this.queryResult = null
      this.clearCommunes()
    },

    async testQuery() {
      this.isLoading = true
      
      try {
        const params = {
          regions: this.selectedRegion ? [this.selectedRegion] : [],
          departements: this.selectedDepartement ? [this.selectedDepartement] : [],
          communes: this.selectedCommune ? [this.selectedCommune] : [],
          csps: this.selectedCSP ? [this.selectedCSP] : [],
          use_population: !!(this.populationMin || this.populationMax),
          population_min: this.populationMin,
          population_max: this.populationMax
        }

        const response = await this.$http.post('/api/lists/query/geo', params)
        this.queryResult = response.data.data
      } catch (e) {
        this.$utils.toast(this.$t('globals.messages.errorFetching'), 'is-danger')
        console.error('Erreur test requête géographique:', e)
      } finally {
        this.isLoading = false
      }
    },

    applyToQuery() {
      // Construire la requête SQL
      let conditions = []
      
      if (this.selectedRegion) {
        conditions.push(`region = '${this.selectedRegion}'`)
      }
      
      if (this.selectedDepartement) {
        conditions.push(`departement_numero = '${this.selectedDepartement}'`)
      }
      
      if (this.selectedCommune) {
        conditions.push(`commune = '${this.selectedCommune}'`)
      }
      
      if (this.selectedCSP) {
        conditions.push(`csp = '${this.selectedCSP}'`)
      }
      
      if (this.populationMin) {
        conditions.push(`population_commune >= ${this.populationMin}`)
      }
      
      if (this.populationMax) {
        conditions.push(`population_commune <= ${this.populationMax}`)
      }

      const query = conditions.length > 0 ? conditions.join(' AND ') : ''
      this.$emit('input', query)
      
      this.$utils.toast(this.$t('geo.queryApplied'), 'is-success')
    },

    formatNumber(num) {
      if (!num) return '0'
      return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
    }
  }
}
</script>

<style scoped>
.geo-selector {
  border: 2px solid #3273dc;
  border-radius: 8px;
  padding: 1.5rem;
  margin: 1rem 0;
  background: #f8f9fa;
}

.geo-controls {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.geo-controls .field:nth-child(3),
.geo-controls .field:nth-child(4),
.geo-controls .field:nth-child(5),
.geo-controls .field:nth-child(6) {
  grid-column: 1 / -1;
}

.commune-list {
  position: absolute;
  z-index: 1000;
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  max-height: 200px;
  overflow-y: auto;
  width: 100%;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.commune-item {
  padding: 0.5rem;
  cursor: pointer;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.commune-item:hover {
  background: #f5f5f5;
}

.commune-item:last-child {
  border-bottom: none;
}

.population {
  font-size: 0.8rem;
  color: #666;
}

@media (max-width: 768px) {
  .geo-controls {
    grid-template-columns: 1fr;
  }
}
</style>