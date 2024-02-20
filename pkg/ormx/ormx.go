package ormx

import (
	_ "embed"
	"fmt"
	"os"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/schema"
)

//go:embed init.sql
var initSql string

// DBConfig GORM DBConfig
type DBConfig struct {
	Debug        bool
	DBType       string
	DSN          string
	MaxLifetime  int
	MaxOpenConns int
	MaxIdleConns int
	TablePrefix  string
}

type SqliteMaster struct {
	name string
}

// New Create gorm.DB instance
func New(c DBConfig) (*gorm.DB, error) {
	var dialector gorm.Dialector

	if _, err := os.Stat("data"); err != nil {
		err := os.Mkdir("data", 0777)
		if err != nil {
			return nil, err
		}
	}
	dialector = sqlite.Open("data/gorm.db")
	gconfig := &gorm.Config{
		NamingStrategy: schema.NamingStrategy{
			TablePrefix:   c.TablePrefix,
			SingularTable: true,
		},
	}

	db, err := gorm.Open(dialector, gconfig)
	if err != nil {
		return nil, err
	}

	if c.Debug {
		db = db.Debug()
	}

	var tableRecord []SqliteMaster
	db.Raw("select name from sqlite_master where type = 'table'").Scan(&tableRecord)
	if len(tableRecord) <= 1 {
		fmt.Println("db is empty. init it.")
		err = db.Debug().Exec(initSql).Error
		if err != nil {
			return nil, err
		}
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxIdleConns(c.MaxIdleConns)
	sqlDB.SetMaxOpenConns(c.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Duration(c.MaxLifetime) * time.Second)
	return db, nil
}
